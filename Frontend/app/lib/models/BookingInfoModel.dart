/// userAddress : "letang"
/// userPhoneNumber : "+543453"
/// userWhatsappPhoneNumber : "+54334"
/// providerAddress : "letang"
/// providerPhoneNumber : "+543453"
/// providerWhatsappPhoneNumber : "+54334"
/// providerNumber : 1
/// userNumber : 3
/// userLatitude : 33.34
/// userLongitude : 67.35
/// providerLatitude : 26.740530333333332
/// providerLongitude : 87.54193883333333
/// bookId : 2
/// startDate : null
/// endDate : null
/// providerBookingDescription : ""
/// userBookingDescription : "ggrddfdgfdfg"
/// serviceName : "plumber"
/// distance : 2073.1605746373652
/// userEmail : "sd1@.com"
/// providerEmail : "sd@.com"
/// providerApprovalStatus : false
/// userApprovalStatus : true
/// providerTaskCompleteStatus : false
/// userTaskCompleteStatus : false
/// advancePaymentAmount : 0
/// createdAt : "2026-09-21T12:33:34.1332Z"
/// requiredAdvancePayment : false

class BookingInfoModel {
  BookingInfoModel({
      String? userAddress, 
      String? userPhoneNumber, 
      String? userWhatsappPhoneNumber, 
      String? providerAddress, 
      String? providerPhoneNumber, 
      String? providerWhatsappPhoneNumber, 
      num? providerNumber, 
      num? userNumber, 
      num? userLatitude, 
      num? userLongitude, 
      num? providerLatitude, 
      num? providerLongitude, 
      num? bookId, 
      dynamic startDate, 
      dynamic endDate, 
      String? providerBookingDescription, 
      String? userBookingDescription, 
      String? serviceName, 
      num? distance, 
      String? userEmail, 
      String? providerEmail, 
      bool? providerApprovalStatus, 
      bool? userApprovalStatus, 
      bool? providerTaskCompleteStatus, 
      bool? userTaskCompleteStatus, 
      num? advancePaymentAmount, 
      String? createdAt, 
      bool? requiredAdvancePayment,}){
    _userAddress = userAddress;
    _userPhoneNumber = userPhoneNumber;
    _userWhatsappPhoneNumber = userWhatsappPhoneNumber;
    _providerAddress = providerAddress;
    _providerPhoneNumber = providerPhoneNumber;
    _providerWhatsappPhoneNumber = providerWhatsappPhoneNumber;
    _providerNumber = providerNumber;
    _userNumber = userNumber;
    _userLatitude = userLatitude;
    _userLongitude = userLongitude;
    _providerLatitude = providerLatitude;
    _providerLongitude = providerLongitude;
    _bookId = bookId;
    _startDate = startDate;
    _endDate = endDate;
    _providerBookingDescription = providerBookingDescription;
    _userBookingDescription = userBookingDescription;
    _serviceName = serviceName;
    _distance = distance;
    _userEmail = userEmail;
    _providerEmail = providerEmail;
    _providerApprovalStatus = providerApprovalStatus;
    _userApprovalStatus = userApprovalStatus;
    _providerTaskCompleteStatus = providerTaskCompleteStatus;
    _userTaskCompleteStatus = userTaskCompleteStatus;
    _advancePaymentAmount = advancePaymentAmount;
    _createdAt = createdAt;
    _requiredAdvancePayment = requiredAdvancePayment;
}

  BookingInfoModel.fromJson(dynamic json) {
    _userAddress = json['userAddress'];
    _userPhoneNumber = json['userPhoneNumber'];
    _userWhatsappPhoneNumber = json['userWhatsappPhoneNumber'];
    _providerAddress = json['providerAddress'];
    _providerPhoneNumber = json['providerPhoneNumber'];
    _providerWhatsappPhoneNumber = json['providerWhatsappPhoneNumber'];
    _providerNumber = json['providerNumber'];
    _userNumber = json['userNumber'];
    _userLatitude = json['userLatitude'];
    _userLongitude = json['userLongitude'];
    _providerLatitude = json['providerLatitude'];
    _providerLongitude = json['providerLongitude'];
    _bookId = json['bookId'];
    _startDate = json['startDate'];
    _endDate = json['endDate'];
    _providerBookingDescription = json['providerBookingDescription'];
    _userBookingDescription = json['userBookingDescription'];
    _serviceName = json['serviceName'];
    _distance = json['distance'];
    _userEmail = json['userEmail'];
    _providerEmail = json['providerEmail'];
    _providerApprovalStatus = json['providerApprovalStatus'];
    _userApprovalStatus = json['userApprovalStatus'];
    _providerTaskCompleteStatus = json['providerTaskCompleteStatus'];
    _userTaskCompleteStatus = json['userTaskCompleteStatus'];
    _advancePaymentAmount = json['advancePaymentAmount'];
    _createdAt = json['createdAt'];
    _requiredAdvancePayment = json['requiredAdvancePayment'];
  }
  String? _userAddress;
  String? _userPhoneNumber;
  String? _userWhatsappPhoneNumber;
  String? _providerAddress;
  String? _providerPhoneNumber;
  String? _providerWhatsappPhoneNumber;
  num? _providerNumber;
  num? _userNumber;
  num? _userLatitude;
  num? _userLongitude;
  num? _providerLatitude;
  num? _providerLongitude;
  num? _bookId;
  dynamic _startDate;
  dynamic _endDate;
  String? _providerBookingDescription;
  String? _userBookingDescription;
  String? _serviceName;
  num? _distance;
  String? _userEmail;
  String? _providerEmail;
  bool? _providerApprovalStatus;
  bool? _userApprovalStatus;
  bool? _providerTaskCompleteStatus;
  bool? _userTaskCompleteStatus;
  num? _advancePaymentAmount;
  String? _createdAt;
  bool? _requiredAdvancePayment;
BookingInfoModel copyWith({  String? userAddress,
  String? userPhoneNumber,
  String? userWhatsappPhoneNumber,
  String? providerAddress,
  String? providerPhoneNumber,
  String? providerWhatsappPhoneNumber,
  num? providerNumber,
  num? userNumber,
  num? userLatitude,
  num? userLongitude,
  num? providerLatitude,
  num? providerLongitude,
  num? bookId,
  dynamic startDate,
  dynamic endDate,
  String? providerBookingDescription,
  String? userBookingDescription,
  String? serviceName,
  num? distance,
  String? userEmail,
  String? providerEmail,
  bool? providerApprovalStatus,
  bool? userApprovalStatus,
  bool? providerTaskCompleteStatus,
  bool? userTaskCompleteStatus,
  num? advancePaymentAmount,
  String? createdAt,
  bool? requiredAdvancePayment,
}) => BookingInfoModel(  userAddress: userAddress ?? _userAddress,
  userPhoneNumber: userPhoneNumber ?? _userPhoneNumber,
  userWhatsappPhoneNumber: userWhatsappPhoneNumber ?? _userWhatsappPhoneNumber,
  providerAddress: providerAddress ?? _providerAddress,
  providerPhoneNumber: providerPhoneNumber ?? _providerPhoneNumber,
  providerWhatsappPhoneNumber: providerWhatsappPhoneNumber ?? _providerWhatsappPhoneNumber,
  providerNumber: providerNumber ?? _providerNumber,
  userNumber: userNumber ?? _userNumber,
  userLatitude: userLatitude ?? _userLatitude,
  userLongitude: userLongitude ?? _userLongitude,
  providerLatitude: providerLatitude ?? _providerLatitude,
  providerLongitude: providerLongitude ?? _providerLongitude,
  bookId: bookId ?? _bookId,
  startDate: startDate ?? _startDate,
  endDate: endDate ?? _endDate,
  providerBookingDescription: providerBookingDescription ?? _providerBookingDescription,
  userBookingDescription: userBookingDescription ?? _userBookingDescription,
  serviceName: serviceName ?? _serviceName,
  distance: distance ?? _distance,
  userEmail: userEmail ?? _userEmail,
  providerEmail: providerEmail ?? _providerEmail,
  providerApprovalStatus: providerApprovalStatus ?? _providerApprovalStatus,
  userApprovalStatus: userApprovalStatus ?? _userApprovalStatus,
  providerTaskCompleteStatus: providerTaskCompleteStatus ?? _providerTaskCompleteStatus,
  userTaskCompleteStatus: userTaskCompleteStatus ?? _userTaskCompleteStatus,
  advancePaymentAmount: advancePaymentAmount ?? _advancePaymentAmount,
  createdAt: createdAt ?? _createdAt,
  requiredAdvancePayment: requiredAdvancePayment ?? _requiredAdvancePayment,
);
  String? get userAddress => _userAddress;
  String? get userPhoneNumber => _userPhoneNumber;
  String? get userWhatsappPhoneNumber => _userWhatsappPhoneNumber;
  String? get providerAddress => _providerAddress;
  String? get providerPhoneNumber => _providerPhoneNumber;
  String? get providerWhatsappPhoneNumber => _providerWhatsappPhoneNumber;
  num? get providerNumber => _providerNumber;
  num? get userNumber => _userNumber;
  num? get userLatitude => _userLatitude;
  num? get userLongitude => _userLongitude;
  num? get providerLatitude => _providerLatitude;
  num? get providerLongitude => _providerLongitude;
  num? get bookId => _bookId;
  dynamic get startDate => _startDate;
  dynamic get endDate => _endDate;
  String? get providerBookingDescription => _providerBookingDescription;
  String? get userBookingDescription => _userBookingDescription;
  String? get serviceName => _serviceName;
  num? get distance => _distance;
  String? get userEmail => _userEmail;
  String? get providerEmail => _providerEmail;
  bool? get providerApprovalStatus => _providerApprovalStatus;
  bool? get userApprovalStatus => _userApprovalStatus;
  bool? get providerTaskCompleteStatus => _providerTaskCompleteStatus;
  bool? get userTaskCompleteStatus => _userTaskCompleteStatus;
  num? get advancePaymentAmount => _advancePaymentAmount;
  String? get createdAt => _createdAt;
  bool? get requiredAdvancePayment => _requiredAdvancePayment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userAddress'] = _userAddress;
    map['userPhoneNumber'] = _userPhoneNumber;
    map['userWhatsappPhoneNumber'] = _userWhatsappPhoneNumber;
    map['providerAddress'] = _providerAddress;
    map['providerPhoneNumber'] = _providerPhoneNumber;
    map['providerWhatsappPhoneNumber'] = _providerWhatsappPhoneNumber;
    map['providerNumber'] = _providerNumber;
    map['userNumber'] = _userNumber;
    map['userLatitude'] = _userLatitude;
    map['userLongitude'] = _userLongitude;
    map['providerLatitude'] = _providerLatitude;
    map['providerLongitude'] = _providerLongitude;
    map['bookId'] = _bookId;
    map['startDate'] = _startDate;
    map['endDate'] = _endDate;
    map['providerBookingDescription'] = _providerBookingDescription;
    map['userBookingDescription'] = _userBookingDescription;
    map['serviceName'] = _serviceName;
    map['distance'] = _distance;
    map['userEmail'] = _userEmail;
    map['providerEmail'] = _providerEmail;
    map['providerApprovalStatus'] = _providerApprovalStatus;
    map['userApprovalStatus'] = _userApprovalStatus;
    map['providerTaskCompleteStatus'] = _providerTaskCompleteStatus;
    map['userTaskCompleteStatus'] = _userTaskCompleteStatus;
    map['advancePaymentAmount'] = _advancePaymentAmount;
    map['createdAt'] = _createdAt;
    map['requiredAdvancePayment'] = _requiredAdvancePayment;
    return map;
  }

}