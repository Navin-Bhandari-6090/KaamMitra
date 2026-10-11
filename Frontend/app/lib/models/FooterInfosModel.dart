/// footerInfoId : 1
/// contactNumber : "+853434354"
/// address : "ddfgdfgfd"
/// email : "user@example.com"
/// socialMediaInfo : "string"

class FooterInfosModel {
  FooterInfosModel({
      num? footerInfoId, 
      String? contactNumber, 
      String? address, 
      String? email, 
      String? socialMediaInfo,}){
    _footerInfoId = footerInfoId;
    _contactNumber = contactNumber;
    _address = address;
    _email = email;
    _socialMediaInfo = socialMediaInfo;
}

  FooterInfosModel.fromJson(dynamic json) {
    _footerInfoId = json['footerInfoId'];
    _contactNumber = json['contactNumber'];
    _address = json['address'];
    _email = json['email'];
    _socialMediaInfo = json['socialMediaInfo'];
  }
  num? _footerInfoId;
  String? _contactNumber;
  String? _address;
  String? _email;
  String? _socialMediaInfo;
FooterInfosModel copyWith({  num? footerInfoId,
  String? contactNumber,
  String? address,
  String? email,
  String? socialMediaInfo,
}) => FooterInfosModel(  footerInfoId: footerInfoId ?? _footerInfoId,
  contactNumber: contactNumber ?? _contactNumber,
  address: address ?? _address,
  email: email ?? _email,
  socialMediaInfo: socialMediaInfo ?? _socialMediaInfo,
);
  num? get footerInfoId => _footerInfoId;
  String? get contactNumber => _contactNumber;
  String? get address => _address;
  String? get email => _email;
  String? get socialMediaInfo => _socialMediaInfo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['footerInfoId'] = _footerInfoId;
    map['contactNumber'] = _contactNumber;
    map['address'] = _address;
    map['email'] = _email;
    map['socialMediaInfo'] = _socialMediaInfo;
    return map;
  }

}