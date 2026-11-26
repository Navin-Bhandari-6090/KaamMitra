/// noticeId : 3
/// providerNumber : 2
/// createdAt : "2026-11-23T08:05:44.730519Z"
/// message : "sjds fsjfsd fsdf fsd"
/// firstName : ""
/// lastName : ""
/// photo : ""
/// serviceName : "driver"

class NoticeProviderModel {
  NoticeProviderModel({
      num? noticeId, 
      num? providerNumber, 
      String? createdAt, 
      String? message, 
      String? firstName, 
      String? lastName, 
      String? photo, 
      String? serviceName,}){
    _noticeId = noticeId;
    _providerNumber = providerNumber;
    _createdAt = createdAt;
    _message = message;
    _firstName = firstName;
    _lastName = lastName;
    _photo = photo;
    _serviceName = serviceName;
}

  NoticeProviderModel.fromJson(dynamic json) {
    _noticeId = json['noticeId'];
    _providerNumber = json['providerNumber'];
    _createdAt = json['createdAt'];
    _message = json['message'];
    _firstName = json['firstName'];
    _lastName = json['lastName'];
    _photo = json['photo'];
    _serviceName = json['serviceName'];
  }
  num? _noticeId;
  num? _providerNumber;
  String? _createdAt;
  String? _message;
  String? _firstName;
  String? _lastName;
  String? _photo;
  String? _serviceName;
NoticeProviderModel copyWith({  num? noticeId,
  num? providerNumber,
  String? createdAt,
  String? message,
  String? firstName,
  String? lastName,
  String? photo,
  String? serviceName,
}) => NoticeProviderModel(  noticeId: noticeId ?? _noticeId,
  providerNumber: providerNumber ?? _providerNumber,
  createdAt: createdAt ?? _createdAt,
  message: message ?? _message,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  photo: photo ?? _photo,
  serviceName: serviceName ?? _serviceName,
);
  num? get noticeId => _noticeId;
  num? get providerNumber => _providerNumber;
  String? get createdAt => _createdAt;
  String? get message => _message;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get photo => _photo;
  String? get serviceName => _serviceName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['noticeId'] = _noticeId;
    map['providerNumber'] = _providerNumber;
    map['createdAt'] = _createdAt;
    map['message'] = _message;
    map['firstName'] = _firstName;
    map['lastName'] = _lastName;
    map['photo'] = _photo;
    map['serviceName'] = _serviceName;
    return map;
  }

}