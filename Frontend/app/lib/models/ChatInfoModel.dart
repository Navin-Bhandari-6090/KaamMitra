/// chatId : 1
/// message : "string"
/// storeAt : "2026-10-09T05:10:31.385839Z"
/// senderNumber : 5
/// receiverNumber : 6

class ChatInfoModel {
  ChatInfoModel({
    num? chatId,
    String? message,
    String? storeAt,
    num? senderNumber,
    num? receiverNumber,
  }) {
    _chatId = chatId;
    _message = message;
    _storeAt = storeAt;
    _senderNumber = senderNumber;
    _receiverNumber = receiverNumber;
  }

  // A message shown before the server has saved it.
  // Its id is the temporary clientId, and it is replaced when the server echoes back.
  ChatInfoModel.optimistic({
    required String id,
    required String text,
    required num senderNumber,
    required num receiverNumber,
  }) {
    _localId = id;
    _message = text;
    _storeAt = DateTime.now().toUtc().toIso8601String();
    _senderNumber = senderNumber;
    _receiverNumber = receiverNumber;
  }

  ChatInfoModel.fromJson(dynamic json) {
    _chatId = json['chatId'];
    _message = json['message'];
    _storeAt = json['storeAt'];
    _senderNumber = json['senderNumber'];
    _receiverNumber = json['receiverNumber'];
  }

  num? _chatId;
  String? _message;
  String? _storeAt;
  num? _senderNumber;
  num? _receiverNumber;
  String? _localId;

  ChatInfoModel copyWith({
    num? chatId,
    String? message,
    String? storeAt,
    num? senderNumber,
    num? receiverNumber,
  }) =>
      ChatInfoModel(
        chatId: chatId ?? _chatId,
        message: message ?? _message,
        storeAt: storeAt ?? _storeAt,
        senderNumber: senderNumber ?? _senderNumber,
        receiverNumber: receiverNumber ?? _receiverNumber,
      );

  num? get chatId => _chatId;
  String? get message => _message;
  String? get storeAt => _storeAt;
  num? get senderNumber => _senderNumber;
  num? get receiverNumber => _receiverNumber;

  // Stable string key used by the chat screen for dedupe and ValueKey.
  // Server messages use chatId. Optimistic messages use the local clientId.
  String get id => _chatId?.toString() ?? _localId ?? '';

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['chatId'] = _chatId;
    map['message'] = _message;
    map['storeAt'] = _storeAt;
    map['senderNumber'] = _senderNumber;
    map['receiverNumber'] = _receiverNumber;
    return map;
  }
}