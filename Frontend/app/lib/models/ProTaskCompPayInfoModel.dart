/// taskCompletePaymentId : 1
/// paymentAmount : 54.32
/// paymentDate : "2026-10-02T08:44:09.334327Z"
/// bookId : 10
/// paymentMethod : "Domestic"
/// paymentPhoto : "/uploads/provider-task-complete-payment/domestic/4eb8a39aa5824ded8a215ac6adaa1b0f.jpg"
/// bookingInfos : null

class ProTaskCompPayInfoModel {
  ProTaskCompPayInfoModel({
      num? taskCompletePaymentId, 
      num? paymentAmount, 
      String? paymentDate, 
      num? bookId, 
      String? paymentMethod, 
      String? paymentPhoto, 
      dynamic bookingInfos,}){
    _taskCompletePaymentId = taskCompletePaymentId;
    _paymentAmount = paymentAmount;
    _paymentDate = paymentDate;
    _bookId = bookId;
    _paymentMethod = paymentMethod;
    _paymentPhoto = paymentPhoto;
    _bookingInfos = bookingInfos;
}

  ProTaskCompPayInfoModel.fromJson(dynamic json) {
    _taskCompletePaymentId = json['taskCompletePaymentId'];
    _paymentAmount = json['paymentAmount'];
    _paymentDate = json['paymentDate'];
    _bookId = json['bookId'];
    _paymentMethod = json['paymentMethod'];
    _paymentPhoto = json['paymentPhoto'];
    _bookingInfos = json['bookingInfos'];
  }
  num? _taskCompletePaymentId;
  num? _paymentAmount;
  String? _paymentDate;
  num? _bookId;
  String? _paymentMethod;
  String? _paymentPhoto;
  dynamic _bookingInfos;
ProTaskCompPayInfoModel copyWith({  num? taskCompletePaymentId,
  num? paymentAmount,
  String? paymentDate,
  num? bookId,
  String? paymentMethod,
  String? paymentPhoto,
  dynamic bookingInfos,
}) => ProTaskCompPayInfoModel(  taskCompletePaymentId: taskCompletePaymentId ?? _taskCompletePaymentId,
  paymentAmount: paymentAmount ?? _paymentAmount,
  paymentDate: paymentDate ?? _paymentDate,
  bookId: bookId ?? _bookId,
  paymentMethod: paymentMethod ?? _paymentMethod,
  paymentPhoto: paymentPhoto ?? _paymentPhoto,
  bookingInfos: bookingInfos ?? _bookingInfos,
);
  num? get taskCompletePaymentId => _taskCompletePaymentId;
  num? get paymentAmount => _paymentAmount;
  String? get paymentDate => _paymentDate;
  num? get bookId => _bookId;
  String? get paymentMethod => _paymentMethod;
  String? get paymentPhoto => _paymentPhoto;
  dynamic get bookingInfos => _bookingInfos;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['taskCompletePaymentId'] = _taskCompletePaymentId;
    map['paymentAmount'] = _paymentAmount;
    map['paymentDate'] = _paymentDate;
    map['bookId'] = _bookId;
    map['paymentMethod'] = _paymentMethod;
    map['paymentPhoto'] = _paymentPhoto;
    map['bookingInfos'] = _bookingInfos;
    return map;
  }

}