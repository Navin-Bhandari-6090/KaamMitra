/// userNumber : 2
/// firstName : "admm"
/// lastName : "admm"
/// email : "sd2@.com"
/// address : "gdfdgf"
/// phoneNumber : "+5343434"
/// whatsappPhoneNumber : "+534354"
/// latitude : 26.7405285
/// longitude : 87.54193525
/// role : "provider"
/// loginAccess : true

class AdminUserInfosModel {
  AdminUserInfosModel({
      num? userNumber, 
      String? firstName, 
      String? lastName, 
      String? email, 
      String? address, 
      String? phoneNumber, 
      String? whatsappPhoneNumber, 
      num? latitude, 
      num? longitude, 
      String? role, 
      bool? loginAccess,}){
    _userNumber = userNumber;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _address = address;
    _phoneNumber = phoneNumber;
    _whatsappPhoneNumber = whatsappPhoneNumber;
    _latitude = latitude;
    _longitude = longitude;
    _role = role;
    _loginAccess = loginAccess;
}

  AdminUserInfosModel.fromJson(dynamic json) {
    _userNumber = json['userNumber'];
    _firstName = json['firstName'];
    _lastName = json['lastName'];
    _email = json['email'];
    _address = json['address'];
    _phoneNumber = json['phoneNumber'];
    _whatsappPhoneNumber = json['whatsappPhoneNumber'];
    _latitude = json['latitude'];
    _longitude = json['longitude'];
    _role = json['role'];
    _loginAccess = json['loginAccess'];
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
  String? _role;
  bool? _loginAccess;
AdminUserInfosModel copyWith({  num? userNumber,
  String? firstName,
  String? lastName,
  String? email,
  String? address,
  String? phoneNumber,
  String? whatsappPhoneNumber,
  num? latitude,
  num? longitude,
  String? role,
  bool? loginAccess,
}) => AdminUserInfosModel(  userNumber: userNumber ?? _userNumber,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  email: email ?? _email,
  address: address ?? _address,
  phoneNumber: phoneNumber ?? _phoneNumber,
  whatsappPhoneNumber: whatsappPhoneNumber ?? _whatsappPhoneNumber,
  latitude: latitude ?? _latitude,
  longitude: longitude ?? _longitude,
  role: role ?? _role,
  loginAccess: loginAccess ?? _loginAccess,
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
  String? get role => _role;
  bool? get loginAccess => _loginAccess;

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
    map['role'] = _role;
    map['loginAccess'] = _loginAccess;
    return map;
  }

}