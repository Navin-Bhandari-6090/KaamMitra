/// userNumber : 1
/// firstName : "ppppp"
/// lastName : "pppp"
/// email : "sd@.com"
/// phoneNumber : "+534334344"
/// whatsappPhoneNumber : "+543434534"
/// latitude : 344.4442
/// longitude : 23.23
/// photo : ""

class ServiceScreenUserInfoModel {
  ServiceScreenUserInfoModel({
      num? userNumber, 
      String? firstName, 
      String? lastName, 
      String? email, 
      String? phoneNumber, 
      String? whatsappPhoneNumber, 
      num? latitude, 
      num? longitude, 
      String? photo,}){
    _userNumber = userNumber;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _phoneNumber = phoneNumber;
    _whatsappPhoneNumber = whatsappPhoneNumber;
    _latitude = latitude;
    _longitude = longitude;
    _photo = photo;
}

  ServiceScreenUserInfoModel.fromJson(dynamic json) {
    _userNumber = json['userNumber'];
    _firstName = json['firstName'];
    _lastName = json['lastName'];
    _email = json['email'];
    _phoneNumber = json['phoneNumber'];
    _whatsappPhoneNumber = json['whatsappPhoneNumber'];
    _latitude = json['latitude'];
    _longitude = json['longitude'];
    _photo = json['photo'];
  }
  num? _userNumber;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phoneNumber;
  String? _whatsappPhoneNumber;
  num? _latitude;
  num? _longitude;
  String? _photo;
ServiceScreenUserInfoModel copyWith({  num? userNumber,
  String? firstName,
  String? lastName,
  String? email,
  String? phoneNumber,
  String? whatsappPhoneNumber,
  num? latitude,
  num? longitude,
  String? photo,
}) => ServiceScreenUserInfoModel(  userNumber: userNumber ?? _userNumber,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  email: email ?? _email,
  phoneNumber: phoneNumber ?? _phoneNumber,
  whatsappPhoneNumber: whatsappPhoneNumber ?? _whatsappPhoneNumber,
  latitude: latitude ?? _latitude,
  longitude: longitude ?? _longitude,
  photo: photo ?? _photo,
);
  num? get userNumber => _userNumber;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  String? get whatsappPhoneNumber => _whatsappPhoneNumber;
  num? get latitude => _latitude;
  num? get longitude => _longitude;
  String? get photo => _photo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userNumber'] = _userNumber;
    map['firstName'] = _firstName;
    map['lastName'] = _lastName;
    map['email'] = _email;
    map['phoneNumber'] = _phoneNumber;
    map['whatsappPhoneNumber'] = _whatsappPhoneNumber;
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    map['photo'] = _photo;
    return map;
  }

}