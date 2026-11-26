/// chatId : 2
/// message : "Hu"
/// storeAt : "2026-11-09T18:17:37.2495Z"
/// senderNumber : 1
/// receiverNumber : 2
/// status : 3
/// deliveredAt : "2026-11-09T18:17:37.2495Z"
/// readAt : "2026-11-09T18:17:37.2495Z"
/// isRead : true   (derived from status, kept for old code)
/// clientId : "abc123"  (only in send / ReceiveMessage payloads)

// Message status. It only moves forward: Sent -> Delivered -> Read.
class ChatMessageStatus {
  static const int sent = 1; // single grey tick
  static const int delivered = 2; // double grey tick
  static const int read = 3; // double blue tick
}

class ChatInfoModel {
  ChatInfoModel({
    num? chatId,
    String? message,
    String? storeAt,
    num? senderNumber,
    num? receiverNumber,
    int? status,
    String? deliveredAt,
    String? readAt,
    String? clientId,
  }) {
    _chatId = chatId;
    _message = message;
    _storeAt = storeAt;
    _senderNumber = senderNumber;
    _receiverNumber = receiverNumber;
    _status = status;
    _deliveredAt = deliveredAt;
    _readAt = readAt;
    _clientId = clientId;
  }

  ChatInfoModel.fromJson(dynamic json) {
    _chatId = json['chatId'];
    _message = json['message'];
    _storeAt = json['storeAt'];
    _senderNumber = json['senderNumber'];
    _receiverNumber = json['receiverNumber'];

    // New servers send "status". Older responses only have "isRead".
    final dynamic rawStatus = json['status'];
    if (rawStatus is num) {
      _status = rawStatus.toInt();
    } else if (json['isRead'] == true) {
      _status = ChatMessageStatus.read;
    } else {
      _status = ChatMessageStatus.sent;
    }

    _deliveredAt = json['deliveredAt'];
    _readAt = json['readAt'];

    final dynamic rawClientId = json['clientId'];
    _clientId = rawClientId == null ? null : rawClientId.toString();
  }

  num? _chatId;
  String? _message;
  String? _storeAt;
  num? _senderNumber;
  num? _receiverNumber;
  int? _status;
  String? _deliveredAt;
  String? _readAt;
  String? _clientId;

  ChatInfoModel copyWith({
    num? chatId,
    String? message,
    String? storeAt,
    num? senderNumber,
    num? receiverNumber,
    int? status,
    String? deliveredAt,
    String? readAt,
    String? clientId,
  }) =>
      ChatInfoModel(
        chatId: chatId ?? _chatId,
        message: message ?? _message,
        storeAt: storeAt ?? _storeAt,
        senderNumber: senderNumber ?? _senderNumber,
        receiverNumber: receiverNumber ?? _receiverNumber,
        status: status ?? _status,
        deliveredAt: deliveredAt ?? _deliveredAt,
        readAt: readAt ?? _readAt,
        clientId: clientId ?? _clientId,
      );

  num? get chatId => _chatId;
  String? get message => _message;
  String? get storeAt => _storeAt;
  num? get senderNumber => _senderNumber;
  num? get receiverNumber => _receiverNumber;
  String? get deliveredAt => _deliveredAt;
  String? get readAt => _readAt;
  String? get clientId => _clientId;

  // Always 1, 2 or 3 (never null).
  int get status => _status ?? ChatMessageStatus.sent;

  bool get isSent => status == ChatMessageStatus.sent;
  bool get isDelivered => status == ChatMessageStatus.delivered;
  bool get isRead => status >= ChatMessageStatus.read;

  // Moves the status forward only, so a late or repeated event can never
  // turn a Read message back into Delivered.
  ChatInfoModel withStatusAtLeast(
      int newStatus, {
        String? deliveredAt,
        String? readAt,
      }) {
    if (newStatus <= status) return this;

    return copyWith(
      status: newStatus,
      deliveredAt: _deliveredAt ?? deliveredAt,
      readAt: newStatus >= ChatMessageStatus.read ? (_readAt ?? readAt) : _readAt,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['chatId'] = _chatId;
    map['message'] = _message;
    map['storeAt'] = _storeAt;
    map['senderNumber'] = _senderNumber;
    map['receiverNumber'] = _receiverNumber;
    map['status'] = status;
    map['deliveredAt'] = _deliveredAt;
    map['readAt'] = _readAt;
    map['isRead'] = isRead;
    map['clientId'] = _clientId;
    return map;
  }
}