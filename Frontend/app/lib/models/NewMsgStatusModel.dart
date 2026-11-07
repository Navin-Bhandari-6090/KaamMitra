/// newMsgId : 7
/// messageReceiverNumber : 5
/// status : true

class NewMsgStatusModel {
  NewMsgStatusModel({
      num? newMsgId, 
      num? messageReceiverNumber, 
      bool? status,}){
    _newMsgId = newMsgId;
    _messageReceiverNumber = messageReceiverNumber;
    _status = status;
}

  NewMsgStatusModel.fromJson(dynamic json) {
    _newMsgId = json['newMsgId'];
    _messageReceiverNumber = json['messageReceiverNumber'];
    _status = json['status'];
  }
  num? _newMsgId;
  num? _messageReceiverNumber;
  bool? _status;
NewMsgStatusModel copyWith({  num? newMsgId,
  num? messageReceiverNumber,
  bool? status,
}) => NewMsgStatusModel(  newMsgId: newMsgId ?? _newMsgId,
  messageReceiverNumber: messageReceiverNumber ?? _messageReceiverNumber,
  status: status ?? _status,
);
  num? get newMsgId => _newMsgId;
  num? get messageReceiverNumber => _messageReceiverNumber;
  bool? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['newMsgId'] = _newMsgId;
    map['messageReceiverNumber'] = _messageReceiverNumber;
    map['status'] = _status;
    return map;
  }

}