/// notId : 9
/// receiverNumber : 5
/// message : "User have upload the advance amount payment photo for the booking id = 4."
/// date : "2026-09-30T16:30:47.41233Z"

class NotificationsInfoModel {
  NotificationsInfoModel({
      num? notId, 
      num? receiverNumber, 
      String? message, 
      String? date,}){
    _notId = notId;
    _receiverNumber = receiverNumber;
    _message = message;
    _date = date;
}

  NotificationsInfoModel.fromJson(dynamic json) {
    _notId = json['notId'];
    _receiverNumber = json['receiverNumber'];
    _message = json['message'];
    _date = json['date'];
  }
  num? _notId;
  num? _receiverNumber;
  String? _message;
  String? _date;
NotificationsInfoModel copyWith({  num? notId,
  num? receiverNumber,
  String? message,
  String? date,
}) => NotificationsInfoModel(  notId: notId ?? _notId,
  receiverNumber: receiverNumber ?? _receiverNumber,
  message: message ?? _message,
  date: date ?? _date,
);
  num? get notId => _notId;
  num? get receiverNumber => _receiverNumber;
  String? get message => _message;
  String? get date => _date;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['notId'] = _notId;
    map['receiverNumber'] = _receiverNumber;
    map['message'] = _message;
    map['date'] = _date;
    return map;
  }

}