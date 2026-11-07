/// userNumber : 4
/// firstName : "aaaa 444"
/// lastName : "aaa"
/// email : "sd3@.com"
/// phoneNumber : "+5363536645"
/// whatsappPhoneNumber : "+56334535443"
/// latitude : 26.740530333333332
/// longitude : 87.54193883333333
/// photo : "/uploads/profile/707fe5a6e88143e7938430656f4e742d.png"
/// address : "gadgs"
/// status : true

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
      String? photo, 
      String? address, 
      bool? status,}){
    _userNumber = userNumber;
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _phoneNumber = phoneNumber;
    _whatsappPhoneNumber = whatsappPhoneNumber;
    _latitude = latitude;
    _longitude = longitude;
    _photo = photo;
    _address = address;
    _status = status;
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
    _address = json['address'];
    _status = json['status'];
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
  String? _address;
  bool? _status;
ServiceScreenUserInfoModel copyWith({  num? userNumber,
  String? firstName,
  String? lastName,
  String? email,
  String? phoneNumber,
  String? whatsappPhoneNumber,
  num? latitude,
  num? longitude,
  String? photo,
  String? address,
  bool? status,
}) => ServiceScreenUserInfoModel(  userNumber: userNumber ?? _userNumber,
  firstName: firstName ?? _firstName,
  lastName: lastName ?? _lastName,
  email: email ?? _email,
  phoneNumber: phoneNumber ?? _phoneNumber,
  whatsappPhoneNumber: whatsappPhoneNumber ?? _whatsappPhoneNumber,
  latitude: latitude ?? _latitude,
  longitude: longitude ?? _longitude,
  photo: photo ?? _photo,
  address: address ?? _address,
  status: status ?? _status,
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
  String? get address => _address;
  bool? get status => _status;

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
    map['address'] = _address;
    map['status'] = _status;
    return map;
  }

}