/// newNotId : 2
/// receiverEmail : "sd@.com"
/// status : true

class NewNotificationsModel {
  NewNotificationsModel({
      num? newNotId, 
      String? receiverEmail, 
      bool? status,}){
    _newNotId = newNotId;
    _receiverEmail = receiverEmail;
    _status = status;
}

  NewNotificationsModel.fromJson(dynamic json) {
    _newNotId = json['newNotId'];
    _receiverEmail = json['receiverEmail'];
    _status = json['status'];
  }
  num? _newNotId;
  String? _receiverEmail;
  bool? _status;
NewNotificationsModel copyWith({  num? newNotId,
  String? receiverEmail,
  bool? status,
}) => NewNotificationsModel(  newNotId: newNotId ?? _newNotId,
  receiverEmail: receiverEmail ?? _receiverEmail,
  status: status ?? _status,
);
  num? get newNotId => _newNotId;
  String? get receiverEmail => _receiverEmail;
  bool? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['newNotId'] = _newNotId;
    map['receiverEmail'] = _receiverEmail;
    map['status'] = _status;
    return map;
  }

}