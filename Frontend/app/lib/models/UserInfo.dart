/// userNumber : 4
/// firstName : "fssd"
/// lastName : "sddsds"
/// email : "user@example1.com"
/// phoneNumber : "+55550634448547750255535670982453752693424087452"
/// whatsappPhoneNumber : "+4671661170239377785110992968776516972478221"
/// password : "ae118a7acd2ff2f77598c7316bced68d92bf8c8f0ca30ffb28f4edf6fc7c2f3d"
/// latitude : 34
/// longitude : 45
/// photo : ""
/// role : "User"

class UserInfo {
  UserInfo({
      num? userNumber, 
      String? firstName, 
      String? lastName, 
      String? email, 
      String? phoneNumber, 
      String? whatsappPhoneNumber, 
      String? password, 
      num? latitude, 
      num? longitude, 
      String? photo, 
      String? role,}){
    _userNumber = userNumber;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _phoneNumber = phoneNumber;
    _whatsappPhoneNumber = whatsappPhoneNumber;
    _password = password;
    _latitude = latitude;
    _longitude = longitude;
    _photo = photo;
    _role = role;
}

  UserInfo.fromJson(dynamic json) {
    _userNumber = json['userNumber'];
    _firstName = json['firstName'];
    _lastName = json['lastName'];
    _email = json['email'];
    _phoneNumber = json['phoneNumber'];
    _whatsappPhoneNumber = json['whatsappPhoneNumber'];
    _password = json['password'];
    _latitude = json['latitude'];
    _longitude = json['longitude'];
    _photo = json['photo'];
    _role = json['role'];
  }
  num? _userNumber;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phoneNumber;
  String? _whatsappPhoneNumber;
  String? _password;
  num? _latitude;
  num? _longitude;
  String? _photo;
  String? _role;
UserInfo copyWith({  num? userNumber,
  String? firstName,
  String? lastName,
  String? email,
  String? phoneNumber,
  String? whatsappPhoneNumber,
  String? password,
  num? latitude,
  num? longitude,
  String? photo,
  String? role,
}) => UserInfo(  userNumber: userNumber ?? _userNumber,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  email: email ?? _email,
  phoneNumber: phoneNumber ?? _phoneNumber,
  whatsappPhoneNumber: whatsappPhoneNumber ?? _whatsappPhoneNumber,
  password: password ?? _password,
  latitude: latitude ?? _latitude,
  longitude: longitude ?? _longitude,
  photo: photo ?? _photo,
  role: role ?? _role,
);
  num? get userNumber => _userNumber;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  String? get whatsappPhoneNumber => _whatsappPhoneNumber;
  String? get password => _password;
  num? get latitude => _latitude;
  num? get longitude => _longitude;
  String? get photo => _photo;
  String? get role => _role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userNumber'] = _userNumber;
    map['firstName'] = _firstName;
    map['lastName'] = _lastName;
    map['email'] = _email;
    map['phoneNumber'] = _phoneNumber;
    map['whatsappPhoneNumber'] = _whatsappPhoneNumber;
    map['password'] = _password;
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    map['photo'] = _photo;
    map['role'] = _role;
    return map;
  }

}