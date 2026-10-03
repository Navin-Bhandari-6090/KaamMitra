/// adminQRID : 1
/// domesticQRPhoto : "/uploads/admin-qr/domestic/55bce3be9b1044d6981919c265639dc4.jpg"
/// internationalQRPhoto : "/uploads/admin-qr/international/5f025fd636a54dc1a0dd0cb9692f6b25.png"

class AdminQrInfoModel {
  AdminQrInfoModel({
      num? adminQRID, 
      String? domesticQRPhoto, 
      String? internationalQRPhoto,}){
    _adminQRID = adminQRID;
    _domesticQRPhoto = domesticQRPhoto;
    _internationalQRPhoto = internationalQRPhoto;
}

  AdminQrInfoModel.fromJson(dynamic json) {
    _adminQRID = json['adminQRID'];
    _domesticQRPhoto = json['domesticQRPhoto'];
    _internationalQRPhoto = json['internationalQRPhoto'];
  }
  num? _adminQRID;
  String? _domesticQRPhoto;
  String? _internationalQRPhoto;
AdminQrInfoModel copyWith({  num? adminQRID,
  String? domesticQRPhoto,
  String? internationalQRPhoto,
}) => AdminQrInfoModel(  adminQRID: adminQRID ?? _adminQRID,
  domesticQRPhoto: domesticQRPhoto ?? _domesticQRPhoto,
  internationalQRPhoto: internationalQRPhoto ?? _internationalQRPhoto,
);
  num? get adminQRID => _adminQRID;
  String? get domesticQRPhoto => _domesticQRPhoto;
  String? get internationalQRPhoto => _internationalQRPhoto;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['adminQRID'] = _adminQRID;
    map['domesticQRPhoto'] = _domesticQRPhoto;
    map['internationalQRPhoto'] = _internationalQRPhoto;
    return map;
  }

}