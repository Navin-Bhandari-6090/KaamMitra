/// userNumber : 5
/// firstName : "aaa55"
/// lastName : "aaa"
/// email : "sd2@.com"
/// address : "gadgs"
/// phoneNumber : "+97788754754"
/// whatsappPhoneNumber : "+97756725436"
/// latitude : 26.740530333333332
/// longitude : 87.54193883333333
/// photo : "/uploads/profile/25a9e08de30741b582a775e89848b3e2.png"
/// role : "provider"
/// loginAccess : true
/// status : true

class UserInfo {
  UserInfo({
      num? userNumber, 
      String? firstName, 
      String? lastName, 
      String? email, 
      String? address, 
      String? phoneNumber, 
      String? whatsappPhoneNumber, 
      num? latitude, 
      num? longitude, 
      String? photo, 
      String? role, 
      bool? loginAccess, 
      bool? status,}){
    _userNumber = userNumber;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _address = address;
    _phoneNumber = phoneNumber;
    _whatsappPhoneNumber = whatsappPhoneNumber;
    _latitude = latitude;
    _longitude = longitude;
    _photo = photo;
    _role = role;
    _loginAccess = loginAccess;
    _status = status;
}

  UserInfo.fromJson(dynamic json) {
    _userNumber = json['userNumber'];
    _firstName = json['firstName'];
    _lastName = json['lastName'];
    _email = json['email'];
    _address = json['address'];
    _phoneNumber = json['phoneNumber'];
    _whatsappPhoneNumber = json['whatsappPhoneNumber'];
    _latitude = json['latitude'];
    _longitude = json['longitude'];
    _photo = json['photo'];
    _role = json['role'];
    _loginAccess = json['loginAccess'];
    _status = json['status'];
  }
  num? _userNumber;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _address;
  String? _phoneNumber;
  String? _whatsappPhoneNumber;
  num? _latitude;
  num? _longitude;
  String? _photo;
  String? _role;
  bool? _loginAccess;
  bool? _status;
UserInfo copyWith({  num? userNumber,
  String? firstName,
  String? lastName,
  String? email,
  String? address,
  String? phoneNumber,
  String? whatsappPhoneNumber,
  num? latitude,
  num? longitude,
  String? photo,
  String? role,
  bool? loginAccess,
  bool? status,
}) => UserInfo(  userNumber: userNumber ?? _userNumber,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  email: email ?? _email,
  address: address ?? _address,
  phoneNumber: phoneNumber ?? _phoneNumber,
  whatsappPhoneNumber: whatsappPhoneNumber ?? _whatsappPhoneNumber,
  latitude: latitude ?? _latitude,
  longitude: longitude ?? _longitude,
  photo: photo ?? _photo,
  role: role ?? _role,
  loginAccess: loginAccess ?? _loginAccess,
  status: status ?? _status,
);
  num? get userNumber => _userNumber;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get address => _address;
  String? get phoneNumber => _phoneNumber;
  String? get whatsappPhoneNumber => _whatsappPhoneNumber;
  num? get latitude => _latitude;
  num? get longitude => _longitude;
  String? get photo => _photo;
  String? get role => _role;
  bool? get loginAccess => _loginAccess;
  bool? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userNumber'] = _userNumber;
    map['firstName'] = _firstName;
    map['lastName'] = _lastName;
    map['email'] = _email;
    map['address'] = _address;
    map['phoneNumber'] = _phoneNumber;
    map['whatsappPhoneNumber'] = _whatsappPhoneNumber;
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    map['photo'] = _photo;
    map['role'] = _role;
    map['loginAccess'] = _loginAccess;
    map['status'] = _status;
    return map;
  }

}