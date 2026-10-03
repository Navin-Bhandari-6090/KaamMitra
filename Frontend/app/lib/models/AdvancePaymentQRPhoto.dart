/// qrId : 1
/// providerEmail : "sd@.com"
/// providerNumber : 1
/// qrPhoto : "/uploads/advance-payment-qr/8c3e5b23c93b4c53824ddc2d5efd1500.jpg"

class AdvancePaymentQrPhoto {
  AdvancePaymentQrPhoto({
      num? qrId, 
      String? providerEmail, 
      num? providerNumber, 
      String? qrPhoto,}){
    _qrId = qrId;
    _providerEmail = providerEmail;
    _providerNumber = providerNumber;
    _qrPhoto = qrPhoto;
}

  AdvancePaymentQrPhoto.fromJson(dynamic json) {
    _qrId = json['qrId'];
    _providerEmail = json['providerEmail'];
    _providerNumber = json['providerNumber'];
    _qrPhoto = json['qrPhoto'];
  }
  num? _qrId;
  String? _providerEmail;
  num? _providerNumber;
  String? _qrPhoto;
AdvancePaymentQrPhoto copyWith({  num? qrId,
  String? providerEmail,
  num? providerNumber,
  String? qrPhoto,
}) => AdvancePaymentQrPhoto(  qrId: qrId ?? _qrId,
  providerEmail: providerEmail ?? _providerEmail,
  providerNumber: providerNumber ?? _providerNumber,
  qrPhoto: qrPhoto ?? _qrPhoto,
);
  num? get qrId => _qrId;
  String? get providerEmail => _providerEmail;
  num? get providerNumber => _providerNumber;
  String? get qrPhoto => _qrPhoto;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['qrId'] = _qrId;
    map['providerEmail'] = _providerEmail;
    map['providerNumber'] = _providerNumber;
    map['qrPhoto'] = _qrPhoto;
    return map;
  }

}