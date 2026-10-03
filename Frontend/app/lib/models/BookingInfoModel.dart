/// userAddress : "gadgs"
/// userPhoneNumber : "+5363536645"
/// userWhatsappPhoneNumber : "+56334535443"
/// providerAddress : "gadgs"
/// providerPhoneNumber : "+5363536645"
/// providerWhatsappPhoneNumber : "+56334535443"
/// providerNumber : 5
/// userNumber : 6
/// userLatitude : 26.740530333333332
/// userLongitude : 87.54193883333333
/// providerLatitude : 26.740530333333332
/// providerLongitude : 87.54193883333333
/// bookId : 10
/// startDate : null
/// endDate : null
/// providerBookingDescription : ""
/// userBookingDescription : "gvddsvds"
/// serviceName : "plumber"
/// providerServiceId : 7
/// serviceId : 1
/// distance : 0
/// userEmail : "sd1@.com"
/// providerEmail : "sd2@.com"
/// providerApprovalStatus : false
/// userApprovalStatus : true
/// providerTaskCompleteStatus : false
/// userTaskCompleteStatus : false
/// advancePaymentAmount : 0
/// createdAt : "2026-10-01T12:26:20.549487Z"
/// ratingValueUser : 5
/// requiredAdvancePayment : false
/// domesticPrice : 56
/// domesticPriceDiscount : 3
/// internationalPrice : 5445
/// internationalPriceDiscount : 3

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
      num? providerServiceId, 
      num? serviceId, 
      num? distance, 
      String? userEmail, 
      String? providerEmail, 
      bool? providerApprovalStatus, 
      bool? userApprovalStatus, 
      bool? providerTaskCompleteStatus, 
      bool? userTaskCompleteStatus, 
      num? advancePaymentAmount, 
      String? createdAt, 
      num? ratingValueUser, 
      bool? requiredAdvancePayment, 
      num? domesticPrice, 
      num? domesticPriceDiscount, 
      num? internationalPrice, 
      num? internationalPriceDiscount,}){
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
    _providerServiceId = providerServiceId;
    _serviceId = serviceId;
    _distance = distance;
    _userEmail = userEmail;
    _providerEmail = providerEmail;
    _providerApprovalStatus = providerApprovalStatus;
    _userApprovalStatus = userApprovalStatus;
    _providerTaskCompleteStatus = providerTaskCompleteStatus;
    _userTaskCompleteStatus = userTaskCompleteStatus;
    _advancePaymentAmount = advancePaymentAmount;
    _createdAt = createdAt;
    _ratingValueUser = ratingValueUser;
    _requiredAdvancePayment = requiredAdvancePayment;
    _domesticPrice = domesticPrice;
    _domesticPriceDiscount = domesticPriceDiscount;
    _internationalPrice = internationalPrice;
    _internationalPriceDiscount = internationalPriceDiscount;
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
    _providerServiceId = json['providerServiceId'];
    _serviceId = json['serviceId'];
    _distance = json['distance'];
    _userEmail = json['userEmail'];
    _providerEmail = json['providerEmail'];
    _providerApprovalStatus = json['providerApprovalStatus'];
    _userApprovalStatus = json['userApprovalStatus'];
    _providerTaskCompleteStatus = json['providerTaskCompleteStatus'];
    _userTaskCompleteStatus = json['userTaskCompleteStatus'];
    _advancePaymentAmount = json['advancePaymentAmount'];
    _createdAt = json['createdAt'];
    _ratingValueUser = json['ratingValueUser'];
    _requiredAdvancePayment = json['requiredAdvancePayment'];
    _domesticPrice = json['domesticPrice'];
    _domesticPriceDiscount = json['domesticPriceDiscount'];
    _internationalPrice = json['internationalPrice'];
    _internationalPriceDiscount = json['internationalPriceDiscount'];
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
  num? _providerServiceId;
  num? _serviceId;
  num? _distance;
  String? _userEmail;
  String? _providerEmail;
  bool? _providerApprovalStatus;
  bool? _userApprovalStatus;
  bool? _providerTaskCompleteStatus;
  bool? _userTaskCompleteStatus;
  num? _advancePaymentAmount;
  String? _createdAt;
  num? _ratingValueUser;
  bool? _requiredAdvancePayment;
  num? _domesticPrice;
  num? _domesticPriceDiscount;
  num? _internationalPrice;
  num? _internationalPriceDiscount;
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
  num? providerServiceId,
  num? serviceId,
  num? distance,
  String? userEmail,
  String? providerEmail,
  bool? providerApprovalStatus,
  bool? userApprovalStatus,
  bool? providerTaskCompleteStatus,
  bool? userTaskCompleteStatus,
  num? advancePaymentAmount,
  String? createdAt,
  num? ratingValueUser,
  bool? requiredAdvancePayment,
  num? domesticPrice,
  num? domesticPriceDiscount,
  num? internationalPrice,
  num? internationalPriceDiscount,
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
  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceId: serviceId ?? _serviceId,
  distance: distance ?? _distance,
  userEmail: userEmail ?? _userEmail,
  providerEmail: providerEmail ?? _providerEmail,
  providerApprovalStatus: providerApprovalStatus ?? _providerApprovalStatus,
  userApprovalStatus: userApprovalStatus ?? _userApprovalStatus,
  providerTaskCompleteStatus: providerTaskCompleteStatus ?? _providerTaskCompleteStatus,
  userTaskCompleteStatus: userTaskCompleteStatus ?? _userTaskCompleteStatus,
  advancePaymentAmount: advancePaymentAmount ?? _advancePaymentAmount,
  createdAt: createdAt ?? _createdAt,
  ratingValueUser: ratingValueUser ?? _ratingValueUser,
  requiredAdvancePayment: requiredAdvancePayment ?? _requiredAdvancePayment,
  domesticPrice: domesticPrice ?? _domesticPrice,
  domesticPriceDiscount: domesticPriceDiscount ?? _domesticPriceDiscount,
  internationalPrice: internationalPrice ?? _internationalPrice,
  internationalPriceDiscount: internationalPriceDiscount ?? _internationalPriceDiscount,
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
  num? get providerServiceId => _providerServiceId;
  num? get serviceId => _serviceId;
  num? get distance => _distance;
  String? get userEmail => _userEmail;
  String? get providerEmail => _providerEmail;
  bool? get providerApprovalStatus => _providerApprovalStatus;
  bool? get userApprovalStatus => _userApprovalStatus;
  bool? get providerTaskCompleteStatus => _providerTaskCompleteStatus;
  bool? get userTaskCompleteStatus => _userTaskCompleteStatus;
  num? get advancePaymentAmount => _advancePaymentAmount;
  String? get createdAt => _createdAt;
  num? get ratingValueUser => _ratingValueUser;
  bool? get requiredAdvancePayment => _requiredAdvancePayment;
  num? get domesticPrice => _domesticPrice;
  num? get domesticPriceDiscount => _domesticPriceDiscount;
  num? get internationalPrice => _internationalPrice;
  num? get internationalPriceDiscount => _internationalPriceDiscount;

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
    map['providerServiceId'] = _providerServiceId;
    map['serviceId'] = _serviceId;
    map['distance'] = _distance;
    map['userEmail'] = _userEmail;
    map['providerEmail'] = _providerEmail;
    map['providerApprovalStatus'] = _providerApprovalStatus;
    map['userApprovalStatus'] = _userApprovalStatus;
    map['providerTaskCompleteStatus'] = _providerTaskCompleteStatus;
    map['userTaskCompleteStatus'] = _userTaskCompleteStatus;
    map['advancePaymentAmount'] = _advancePaymentAmount;
    map['createdAt'] = _createdAt;
    map['ratingValueUser'] = _ratingValueUser;
    map['requiredAdvancePayment'] = _requiredAdvancePayment;
    map['domesticPrice'] = _domesticPrice;
    map['domesticPriceDiscount'] = _domesticPriceDiscount;
    map['internationalPrice'] = _internationalPrice;
    map['internationalPriceDiscount'] = _internationalPriceDiscount;
    return map;
  }

}