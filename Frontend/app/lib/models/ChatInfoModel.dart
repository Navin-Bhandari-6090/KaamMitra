/// chatId : 2
/// message : "Hu"
/// storeAt : "2026-11-09T18:17:37.2495Z"
/// senderNumber : 1
/// receiverNumber : 2
/// isRead : true
/// readAt : "2026-11-09T18:17:37.2495Z"

class ChatInfoModel {
  ChatInfoModel({
      num? chatId, 
      String? message, 
      String? storeAt, 
      num? senderNumber, 
      num? receiverNumber, 
      bool? isRead, 
      String? readAt,}){
    _chatId = chatId;
    _message = message;
    _storeAt = storeAt;
    _senderNumber = senderNumber;
    _receiverNumber = receiverNumber;
    _isRead = isRead;
    _readAt = readAt;
}

  ChatInfoModel.fromJson(dynamic json) {
    _chatId = json['chatId'];
    _message = json['message'];
    _storeAt = json['storeAt'];
    _senderNumber = json['senderNumber'];
    _receiverNumber = json['receiverNumber'];
    _isRead = json['isRead'];
    _readAt = json['readAt'];
  }
  num? _chatId;
  String? _message;
  String? _storeAt;
  num? _senderNumber;
  num? _receiverNumber;
  bool? _isRead;
  String? _readAt;
ChatInfoModel copyWith({  num? chatId,
  String? message,
  String? storeAt,
  num? senderNumber,
  num? receiverNumber,
  bool? isRead,
  String? readAt,
}) => ChatInfoModel(  chatId: chatId ?? _chatId,
  message: message ?? _message,
  storeAt: storeAt ?? _storeAt,
  senderNumber: senderNumber ?? _senderNumber,
  receiverNumber: receiverNumber ?? _receiverNumber,
  isRead: isRead ?? _isRead,
  readAt: readAt ?? _readAt,
);
  num? get chatId => _chatId;
  String? get message => _message;
  String? get storeAt => _storeAt;
  num? get senderNumber => _senderNumber;
  num? get receiverNumber => _receiverNumber;
  bool? get isRead => _isRead;
  String? get readAt => _readAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['chatId'] = _chatId;
    map['message'] = _message;
    map['storeAt'] = _storeAt;
    map['senderNumber'] = _senderNumber;
    map['receiverNumber'] = _receiverNumber;
    map['isRead'] = _isRead;
    map['readAt'] = _readAt;
    return map;
  }

}