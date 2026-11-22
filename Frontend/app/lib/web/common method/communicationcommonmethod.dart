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
    this.lastIsRead = true,
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
  final bool lastIsRead;
  final int unreadCount;

  String get photoUrl => MsgPhotoUrl(photo);
  DateTime? get lastTime => MsgParseTime(lastMessageAt);
  bool get hasMessage => lastMessage.trim().isNotEmpty;

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
      lastIsRead: _toBool(j['lastIsRead'], true),
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
    bool? lastIsRead,
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
      lastIsRead: lastIsRead ?? this.lastIsRead,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// One message of a chat (used by the message screen).
class MsgMessage {
  const MsgMessage({
    required this.chatId,
    required this.message,
    required this.storeAt,
    required this.senderNumber,
    required this.receiverNumber,
    this.isRead = false,
    this.clientId = '',
  });

  final int chatId;
  final String message;
  final String storeAt;
  final int senderNumber;
  final int receiverNumber;
  final bool isRead;
  final String clientId;

  DateTime? get time => MsgParseTime(storeAt);

  factory MsgMessage.fromJson(Map<String, dynamic> j) {
    return MsgMessage(
      chatId: _toInt(j['chatId']),
      message: _toStr(j['message']),
      storeAt: _toStr(j['storeAt']),
      senderNumber: _toInt(j['senderNumber']),
      receiverNumber: _toInt(j['receiverNumber']),
      isRead: _toBool(j['isRead']),
      clientId: _toStr(j['clientId']),
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
}

class MsgSendResult {
  MsgSendResult({
    required this.ok,
    this.message,
    this.statusCode = 0,
    this.error = '',
  });

  final bool ok;
  final MsgMessage? message;
  final int statusCode;
  final String error; // readable reason from the server (400 / 403 / 404)
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

// Sends a message. The server saves it and pushes it live to the receiver.
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

// Marks everything from one person as read. Returns true on success.
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

    return response.statusCode == 200;
  } catch (e) {
    // print('MsgMarkRead error: $e');
    return false;
  }
}

// Total unread messages for me. Returns -1 when the request fails.
Future<int> MsgGetUnreadTotal({required String jwt}) async {
  try {
    final response = await http
        .get(Uri.parse('${_Base}unread'), headers: _Headers(jwt))
        .timeout(_Timeout);

    if (response.statusCode != 200) return -1;

    final dynamic json = jsonDecode(response.body);
    if (json is! Map) return -1;

    return _toInt(json['total'], -1);
  } catch (e) {
    // print('MsgGetUnreadTotal error: $e');
    return -1;
  }
}