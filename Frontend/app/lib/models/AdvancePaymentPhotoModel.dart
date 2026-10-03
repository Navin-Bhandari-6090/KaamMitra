/// paymentId : 1
/// paymentPhoto : "/uploads/advance-payment/beb69d1c7b3c4f10ac6b392c29d7c240.png"
/// bookId : 2

class AdvancePaymentPhotoModel {
  AdvancePaymentPhotoModel({
      num? paymentId, 
      String? paymentPhoto, 
      num? bookId,}){
    _paymentId = paymentId;
    _paymentPhoto = paymentPhoto;
    _bookId = bookId;
}

  AdvancePaymentPhotoModel.fromJson(dynamic json) {
    _paymentId = json['paymentId'];
    _paymentPhoto = json['paymentPhoto'];
    _bookId = json['bookId'];
  }
  num? _paymentId;
  String? _paymentPhoto;
  num? _bookId;
AdvancePaymentPhotoModel copyWith({  num? paymentId,
  String? paymentPhoto,
  num? bookId,
}) => AdvancePaymentPhotoModel(  paymentId: paymentId ?? _paymentId,
  paymentPhoto: paymentPhoto ?? _paymentPhoto,
  bookId: bookId ?? _bookId,
);
  num? get paymentId => _paymentId;
  String? get paymentPhoto => _paymentPhoto;
  num? get bookId => _bookId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['paymentId'] = _paymentId;
    map['paymentPhoto'] = _paymentPhoto;
    map['bookId'] = _bookId;
    return map;
  }

}