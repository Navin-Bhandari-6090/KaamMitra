/// notId : 15
/// receiverEmail : "sd@.com"
/// message : "You have been booked by sd@.com for painter."
/// date : "2026-09-20T09:08:45.348005Z"

class NotificationsInfoModel {
  NotificationsInfoModel({
      num? notId, 
      String? receiverEmail, 
      String? message, 
      String? date,}){
    _notId = notId;
    _receiverEmail = receiverEmail;
    _message = message;
    _date = date;
}

  NotificationsInfoModel.fromJson(dynamic json) {
    _notId = json['notId'];
    _receiverEmail = json['receiverEmail'];
    _message = json['message'];
    _date = json['date'];
  }
  num? _notId;
  String? _receiverEmail;
  String? _message;
  String? _date;
NotificationsInfoModel copyWith({  num? notId,
  String? receiverEmail,
  String? message,
  String? date,
}) => NotificationsInfoModel(  notId: notId ?? _notId,
  receiverEmail: receiverEmail ?? _receiverEmail,
  message: message ?? _message,
  date: date ?? _date,
);
  num? get notId => _notId;
  String? get receiverEmail => _receiverEmail;
  String? get message => _message;
  String? get date => _date;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['notId'] = _notId;
    map['receiverEmail'] = _receiverEmail;
    map['message'] = _message;
    map['date'] = _date;
    return map;
  }

}