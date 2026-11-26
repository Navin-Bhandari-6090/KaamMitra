import 'dart:convert';

import 'package:app/constant/Server_Database.dart';
import 'package:http/http.dart' as http;

// =============================================================================
// CHAT COMMUNICATION: models + REST calls of api/Chat (new endpoints).
// No UI code here (no toasts, no navigation): the GetX files decide what to
// show. Every call returns a result object and never throws.
// =============================================================================

const String _Base = '${Backend_Server_Url}api/Chat/';
const Duration _Timeout = Duration(seconds: 20);

// -----------------------------------------------------------------------------
// USER NOT VALID (status 525)
// The server returns 525 when the JWT is bad, the user no longer exists, or
// KaamMitra blocked the user. The app must log the user out.
//
// Set MsgOnNotValidated ONCE (for example after login, or in main) to the
// function that logs the user out. Every call below runs it automatically on
// 525, at most once, so many requests failing together log out only once.
// Call MsgResetNotValidated() after a successful login.
// The result objects also expose "notValidated" if a screen wants to check.
// -----------------------------------------------------------------------------
const int MsgNotValidatedCode = 525;

void Function()? MsgOnNotValidated;
bool _NotValidatedFired = false;

void MsgResetNotValidated() {
  _NotValidatedFired = false;
}

// Returns true when the status code is 525 (and starts the logout once).
bool _CheckNotValidated(int statusCode) {
  if (statusCode != MsgNotValidatedCode) return false;

  if (!_NotValidatedFired) {
    _NotValidatedFired = true;
    try {
      MsgOnNotValidated?.call();
    } catch (e) {
      // print('MsgOnNotValidated error: $e');
    }
  }

  return true;
}

// -----------------------------------------------------------------------------
// MESSAGE STATUS (same numbers as the server). It only moves forward.
//   1 Sent       single grey tick
//   2 Delivered  double grey tick
//   3 Read       double blue tick
// -----------------------------------------------------------------------------
class MsgStatus {
  static const int sent = 1;
  static const int delivered = 2;
  static const int read = 3;
}

Map<String, String> _Headers(String jwt, {bool json = false}) {
  return {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    'Authorization': 'Bearer $jwt',
  };
}

// -----------------------------------------------------------------------------
// SAFE PARSERS (never throw, whatever the server sends)
// -----------------------------------------------------------------------------
int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? fallback;
}

String _toStr(dynamic v) => v == null ? '' : '$v';

bool _toBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final String s = '${v ?? ''}'.trim().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return fallback;
}

// Reads a status. New servers send a number. Old responses only have a bool
// read flag, so fall back to it. The result is always 1, 2 or 3.
int _toStatus(dynamic status, dynamic readFlag, {int unreadFallback = 1}) {
  if (status is num) {
    return status.toInt().clamp(MsgStatus.sent, MsgStatus.read);
  }

  final int parsed = int.tryParse('${status ?? ''}') ?? 0;
  if (parsed >= MsgStatus.sent && parsed <= MsgStatus.read) return parsed;

  return _toBool(readFlag) ? MsgStatus.read : unreadFallback;
}

// Server time is UTC. If it arrives without a 'Z', force UTC, then convert to
// the device's local time.
DateTime? MsgParseTime(String? raw) {
  try {
    final String s = (raw ?? '').trim();
    if (s.isEmpty) return null;

    final bool hasZone = s.endsWith('Z') ||
        s.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);

    return DateTime.tryParse(hasZone ? s : '${s}Z')?.toLocal();
  } catch (e) {
    return null;
  }
}

// Photo is stored as a relative path like /uploads/profile/abc.jpg.
// Returns '' when there is no photo (the UI then shows a people icon).
String MsgPhotoUrl(String? path) {
  final String p = (path ?? '').trim();
  if (p.isEmpty) return '';
  if (p.startsWith('http://') || p.startsWith('https://')) return p;

  final String base = Backend_Server_Url.endsWith('/')
      ? Backend_Server_Url
      : '$Backend_Server_Url/';
  return base + (p.startsWith('/') ? p.substring(1) : p);
}

// =============================================================================
// MODELS
// =============================================================================

// One chat card: a person plus the state of the conversation with them.
// Search results with no chat yet use the same model (lastChatId = 0).
class MsgConversation {
  const MsgConversation({
    required this.userNumber,
    required this.name,
    this.photo = '',
    this.blocked = false,
    this.lastChatId = 0,
    this.lastMessage = '',
    this.lastSenderNumber = 0,
    this.lastMessageAt = '',
    this.lastStatus = MsgStatus.read,
    this.unreadCount = 0,
  });

  final int userNumber;
  final String name;
  final String photo; // raw path as stored on the server
  final bool blocked;
  final int lastChatId;
  final String lastMessage;
  final int lastSenderNumber;
  final String lastMessageAt;

  // Status of the LAST message (1 Sent, 2 Delivered, 3 Read). The card shows
  // this tick only when the last message was sent by me.
  final int lastStatus;
  final int unreadCount;

  String get photoUrl => MsgPhotoUrl(photo);
  DateTime? get lastTime => MsgParseTime(lastMessageAt);
  bool get hasMessage => lastMessage.trim().isNotEmpty;
  bool get lastIsRead => lastStatus >= MsgStatus.read;

  factory MsgConversation.fromJson(Map<String, dynamic> j) {
    final int number = _toInt(j['userNumber']);
    final String name = _toStr(j['name']).trim();

    return MsgConversation(
      userNumber: number,
      name: name.isEmpty ? 'User $number' : name,
      photo: _toStr(j['photo']).trim(),
      blocked: _toBool(j['blocked']),
      lastChatId: _toInt(j['lastChatId']),
      lastMessage: _toStr(j['lastMessage']),
      lastSenderNumber: _toInt(j['lastSenderNumber']),
      lastMessageAt: _toStr(j['lastMessageAt']),
      lastStatus: _toStatus(
        j['lastStatus'],
        j['lastIsRead'],
        unreadFallback: MsgStatus.delivered,
      ),
      unreadCount: _toInt(j['unreadCount']),
    );
  }

  MsgConversation copyWith({
    String? name,
    String? photo,
    int? lastChatId,
    String? lastMessage,
    int? lastSenderNumber,
    String? lastMessageAt,
    int? lastStatus,
    int? unreadCount,
  }) {
    return MsgConversation(
      userNumber: userNumber,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      blocked: blocked,
      lastChatId: lastChatId ?? this.lastChatId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderNumber: lastSenderNumber ?? this.lastSenderNumber,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastStatus: lastStatus ?? this.lastStatus,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  // Moves the last message's status forward only (never back).
  MsgConversation withLastStatusAtLeast(int newStatus) {
    if (newStatus <= lastStatus) return this;
    return copyWith(lastStatus: newStatus);
  }
}

// One message of a chat (used by the message screen).
// chatId 0 means "not saved yet" (a temporary bubble while sending).
class MsgMessage {
  const MsgMessage({
    required this.chatId,
    required this.message,
    required this.storeAt,
    required this.senderNumber,
    required this.receiverNumber,
    this.status = MsgStatus.sent,
    this.deliveredAt = '',
    this.readAt = '',
    this.clientId = '',
  });

  final int chatId;
  final String message;
  final String storeAt;
  final int senderNumber;
  final int receiverNumber;

  // 1 Sent, 2 Delivered, 3 Read. Always one of these.
  final int status;
  final String deliveredAt;
  final String readAt;
  final String clientId;

  DateTime? get time => MsgParseTime(storeAt);
  DateTime? get deliveredTime => MsgParseTime(deliveredAt);
  DateTime? get readTime => MsgParseTime(readAt);

  bool get isPending => chatId <= 0;
  bool get isSent => status == MsgStatus.sent;
  bool get isDelivered => status == MsgStatus.delivered;
  bool get isRead => status >= MsgStatus.read;

  factory MsgMessage.fromJson(Map<String, dynamic> j) {
    return MsgMessage(
      chatId: _toInt(j['chatId']),
      message: _toStr(j['message']),
      storeAt: _toStr(j['storeAt']),
      senderNumber: _toInt(j['senderNumber']),
      receiverNumber: _toInt(j['receiverNumber']),
      status: _toStatus(j['status'], j['isRead']),
      deliveredAt: _toStr(j['deliveredAt']),
      readAt: _toStr(j['readAt']),
      clientId: _toStr(j['clientId']),
    );
  }

  MsgMessage copyWith({
    int? chatId,
    String? message,
    String? storeAt,
    int? status,
    String? deliveredAt,
    String? readAt,
    String? clientId,
  }) {
    return MsgMessage(
      chatId: chatId ?? this.chatId,
      message: message ?? this.message,
      storeAt: storeAt ?? this.storeAt,
      senderNumber: senderNumber,
      receiverNumber: receiverNumber,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      clientId: clientId ?? this.clientId,
    );
  }

  // Moves the status forward only, so a late or repeated event can never turn
  // a Read message back into Delivered.
  MsgMessage withStatusAtLeast(
      int newStatus, {
        String? deliveredAt,
        String? readAt,
      }) {
    if (newStatus <= status) return this;

    return copyWith(
      status: newStatus,
      deliveredAt: this.deliveredAt.isNotEmpty ? this.deliveredAt : deliveredAt,
      readAt: newStatus >= MsgStatus.read
          ? (this.readAt.isNotEmpty ? this.readAt : readAt)
          : this.readAt,
    );
  }
}

// =============================================================================
// RESULTS
// =============================================================================
class MsgListResult {
  MsgListResult({
    required this.ok,
    this.items = const <MsgConversation>[],
    this.hasMore = false,
    this.statusCode = 0, // 0 = no response (network error / timeout)
    this.meName = '',
    this.mePhoto = '',
  });

  final bool ok;
  final List<MsgConversation> items;
  final bool hasMore;
  final int statusCode;
  final String meName;
  final String mePhoto;

  // True when the user must be logged out (status 525).
  bool get notValidated => statusCode == MsgNotValidatedCode;
}

class MsgMessagesResult {
  MsgMessagesResult({
    required this.ok,
    this.messages = const <MsgMessage>[],
    this.hasMore = false,
    this.statusCode = 0,
    this.currentUserPhoto = '',
    this.otherUserPhoto = '',
  });

  final bool ok;
  final List<MsgMessage> messages;
  final bool hasMore;
  final int statusCode;
  final String currentUserPhoto;
  final String otherUserPhoto;

  bool get notValidated => statusCode == MsgNotValidatedCode;
}

class MsgSendResult {
  MsgSendResult({
    required this.ok,
    this.message,
    this.statusCode = 0,
    this.error = '',
  });

  final bool ok;
  final MsgMessage? message; // the saved message, with its first status
  final int statusCode;
  final String error; // readable reason from the server (400 / 403 / 404)

  bool get notValidated => statusCode == MsgNotValidatedCode;
}

// =============================================================================
// API CALLS
// =============================================================================
MsgListResult _ParseList(String body) {
  final dynamic json = jsonDecode(body);
  if (json is! Map) return MsgListResult(ok: false);

  final dynamic raw = json['items'];
  final List<MsgConversation> items = raw is List
      ? raw
      .whereType<Map>()
      .map((e) => MsgConversation.fromJson(Map<String, dynamic>.from(e)))
      .where((c) => c.userNumber > 0)
      .toList()
      : <MsgConversation>[];

  String meName = '';
  String mePhoto = '';
  final dynamic me = json['me'];
  if (me is Map) {
    meName = '${me['name'] ?? ''}'.trim();
    mePhoto = '${me['photo'] ?? ''}'.trim();
  }

  return MsgListResult(
    ok: true,
    items: items,
    hasMore: json['hasMore'] == true,
    statusCode: 200,
    meName: meName,
    mePhoto: mePhoto,
  );
}

// My conversations, newest first. Page 1 also returns my own name + photo.
Future<MsgListResult> MsgGetConversations({
  required String jwt,
  required int page,
  int pageSize = 30,
}) async {
  try {
    final response = await http
        .get(
      Uri.parse('${_Base}conversations?page=$page&pageSize=$pageSize'),
      headers: _Headers(jwt),
    )
        .timeout(_Timeout);

    _CheckNotValidated(response.statusCode);

    if (response.statusCode != 200) {
      return MsgListResult(ok: false, statusCode: response.statusCode);
    }
    return _ParseList(response.body);
  } catch (e) {
    // print('MsgGetConversations error: $e');
    return MsgListResult(ok: false);
  }
}

// Search people by username or user id. Empty query = everyone (paged).
Future<MsgListResult> MsgSearchUsers({
  required String jwt,
  required String query,
  required int page,
  int pageSize = 30,
}) async {
  try {
    final String q = Uri.encodeQueryComponent(query.trim());
    final response = await http
        .get(
      Uri.parse('${_Base}searchusers?q=$q&page=$page&pageSize=$pageSize'),
      headers: _Headers(jwt),
    )
        .timeout(_Timeout);

    _CheckNotValidated(response.statusCode);

    if (response.statusCode != 200) {
      return MsgListResult(ok: false, statusCode: response.statusCode);
    }
    return _ParseList(response.body);
  } catch (e) {
    // print('MsgSearchUsers error: $e');
    return MsgListResult(ok: false);
  }
}

// One page of a chat. First page = newest messages (oldest -> newest order).
// Pass beforeChatId (the oldest ChatId you have) to load older messages.
Future<MsgMessagesResult> MsgGetMessages({
  required String jwt,
  required int userNumber,
  int? beforeChatId,
  int limit = 30,
}) async {
  try {
    final response = await http
        .post(
      Uri.parse('${_Base}messages'),
      headers: _Headers(jwt, json: true),
      body: jsonEncode({
        'UserNumber': userNumber,
        'BeforeChatId': beforeChatId,
        'Limit': limit,
      }),
    )
        .timeout(_Timeout);

    _CheckNotValidated(response.statusCode);

    if (response.statusCode != 200) {
      return MsgMessagesResult(ok: false, statusCode: response.statusCode);
    }

    final dynamic json = jsonDecode(response.body);
    if (json is! Map) return MsgMessagesResult(ok: false);

    final dynamic raw = json['messages'];
    final List<MsgMessage> list = raw is List
        ? raw
        .whereType<Map>()
        .map((e) => MsgMessage.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.chatId > 0)
        .toList()
        : <MsgMessage>[];

    return MsgMessagesResult(
      ok: true,
      messages: list,
      hasMore: json['hasMore'] == true,
      statusCode: 200,
      currentUserPhoto: _toStr(json['currentUserPhoto']).trim(),
      otherUserPhoto: _toStr(json['otherUserPhoto']).trim(),
    );
  } catch (e) {
    // print('MsgGetMessages error: $e');
    return MsgMessagesResult(ok: false);
  }
}

// Sends a message. The server saves it with its first status (Sent,
// Delivered or Read) and pushes it live to the receiver.
Future<MsgSendResult> MsgSendMessage({
  required String jwt,
  required int receiverNumber,
  required String message,
  required String clientId,
}) async {
  try {
    final response = await http
        .post(
      Uri.parse('${_Base}send'),
      headers: _Headers(jwt, json: true),
      body: jsonEncode({
        'ReceiverNumber': receiverNumber,
        'Message': message.trim(),
        'ClientId': clientId,
      }),
    )
        .timeout(_Timeout);

    _CheckNotValidated(response.statusCode);

    if (response.statusCode == 200) {
      final dynamic json = jsonDecode(response.body);
      if (json is Map) {
        return MsgSendResult(
          ok: true,
          statusCode: 200,
          message: MsgMessage.fromJson(Map<String, dynamic>.from(json)),
        );
      }
      return MsgSendResult(ok: false, statusCode: 200);
    }

    String error = '';
    if (response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 404) {
      error = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
    }
    return MsgSendResult(
      ok: false,
      statusCode: response.statusCode,
      error: error,
    );
  } catch (e) {
    // print('MsgSendMessage error: $e');
    return MsgSendResult(ok: false);
  }
}

// Marks everything from one person as read (fallback when SignalR is not
// connected; the hub's OpenChat normally does this). Returns true on success.
Future<bool> MsgMarkRead({
  required String jwt,
  required int userNumber,
}) async {
  try {
    final response = await http
        .post(
      Uri.parse('${_Base}markread'),
      headers: _Headers(jwt, json: true),
      body: jsonEncode({'UserNumber': userNumber}),
    )
        .timeout(_Timeout);

    _CheckNotValidated(response.statusCode);

    return response.statusCode == 200;
  } catch (e) {
    // print('MsgMarkRead error: $e');
    return false;
  }
}

// Total unread messages for me (Sent + Delivered, not yet Read).
// Returns -1 when the request fails.
Future<int> MsgGetUnreadTotal({required String jwt}) async {
  try {
    final response = await http
        .get(Uri.parse('${_Base}unread'), headers: _Headers(jwt))
        .timeout(_Timeout);

    _CheckNotValidated(response.statusCode);

    if (response.statusCode != 200) return -1;

    final dynamic json = jsonDecode(response.body);
    if (json is! Map) return -1;

    return _toInt(json['total'], -1);
  } catch (e) {
    // print('MsgGetUnreadTotal error: $e');
    return -1;
  }
}