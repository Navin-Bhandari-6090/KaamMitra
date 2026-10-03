/// newNotId : 1
/// receiverNumber : 5
/// status : true

class NewNotificationsModel {
  NewNotificationsModel({
      num? newNotId, 
      num? receiverNumber, 
      bool? status,}){
    _newNotId = newNotId;
    _receiverNumber = receiverNumber;
    _status = status;
}

  NewNotificationsModel.fromJson(dynamic json) {
    _newNotId = json['newNotId'];
    _receiverNumber = json['receiverNumber'];
    _status = json['status'];
  }
  num? _newNotId;
  num? _receiverNumber;
  bool? _status;
NewNotificationsModel copyWith({  num? newNotId,
  num? receiverNumber,
  bool? status,
}) => NewNotificationsModel(  newNotId: newNotId ?? _newNotId,
  receiverNumber: receiverNumber ?? _receiverNumber,
  status: status ?? _status,
);
  num? get newNotId => _newNotId;
  num? get receiverNumber => _receiverNumber;
  bool? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['newNotId'] = _newNotId;
    map['receiverNumber'] = _receiverNumber;
    map['status'] = _status;
    return map;
  }

}