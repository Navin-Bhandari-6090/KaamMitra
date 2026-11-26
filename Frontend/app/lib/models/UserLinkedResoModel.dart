/// providerServiceInfo : "1&2"
/// providerServiceResourcesInfo : ""
/// resourcesNoPerUserInfo : "2&3"
/// bookingInfos : ""
/// notificationInfos : "1"
/// newNotificationInfos : "1"
/// advancePaymentInfos : ""
/// advancePaymentQrInfos : ""
/// chatInfos : "7&19&20&1&5&11&13&16&17&26"
/// noticeInfos : "1&2"
/// sharedMediaInfos : "1&3"
/// ratingInfos : ""

class UserLinkedResoModel {
  UserLinkedResoModel({
      String? providerServiceInfo, 
      String? providerServiceResourcesInfo, 
      String? resourcesNoPerUserInfo, 
      String? bookingInfos, 
      String? notificationInfos, 
      String? newNotificationInfos, 
      String? advancePaymentInfos, 
      String? advancePaymentQrInfos, 
      String? chatInfos, 
      String? noticeInfos, 
      String? sharedMediaInfos, 
      String? ratingInfos,}){
    _providerServiceInfo = providerServiceInfo;
    _providerServiceResourcesInfo = providerServiceResourcesInfo;
    _resourcesNoPerUserInfo = resourcesNoPerUserInfo;
    _bookingInfos = bookingInfos;
    _notificationInfos = notificationInfos;
    _newNotificationInfos = newNotificationInfos;
    _advancePaymentInfos = advancePaymentInfos;
    _advancePaymentQrInfos = advancePaymentQrInfos;
    _chatInfos = chatInfos;
    _noticeInfos = noticeInfos;
    _sharedMediaInfos = sharedMediaInfos;
    _ratingInfos = ratingInfos;
}

  UserLinkedResoModel.fromJson(dynamic json) {
    _providerServiceInfo = json['providerServiceInfo'];
    _providerServiceResourcesInfo = json['providerServiceResourcesInfo'];
    _resourcesNoPerUserInfo = json['resourcesNoPerUserInfo'];
    _bookingInfos = json['bookingInfos'];
    _notificationInfos = json['notificationInfos'];
    _newNotificationInfos = json['newNotificationInfos'];
    _advancePaymentInfos = json['advancePaymentInfos'];
    _advancePaymentQrInfos = json['advancePaymentQrInfos'];
    _chatInfos = json['chatInfos'];
    _noticeInfos = json['noticeInfos'];
    _sharedMediaInfos = json['sharedMediaInfos'];
    _ratingInfos = json['ratingInfos'];
  }
  String? _providerServiceInfo;
  String? _providerServiceResourcesInfo;
  String? _resourcesNoPerUserInfo;
  String? _bookingInfos;
  String? _notificationInfos;
  String? _newNotificationInfos;
  String? _advancePaymentInfos;
  String? _advancePaymentQrInfos;
  String? _chatInfos;
  String? _noticeInfos;
  String? _sharedMediaInfos;
  String? _ratingInfos;
UserLinkedResoModel copyWith({  String? providerServiceInfo,
  String? providerServiceResourcesInfo,
  String? resourcesNoPerUserInfo,
  String? bookingInfos,
  String? notificationInfos,
  String? newNotificationInfos,
  String? advancePaymentInfos,
  String? advancePaymentQrInfos,
  String? chatInfos,
  String? noticeInfos,
  String? sharedMediaInfos,
  String? ratingInfos,
}) => UserLinkedResoModel(  providerServiceInfo: providerServiceInfo ?? _providerServiceInfo,
  providerServiceResourcesInfo: providerServiceResourcesInfo ?? _providerServiceResourcesInfo,
  resourcesNoPerUserInfo: resourcesNoPerUserInfo ?? _resourcesNoPerUserInfo,
  bookingInfos: bookingInfos ?? _bookingInfos,
  notificationInfos: notificationInfos ?? _notificationInfos,
  newNotificationInfos: newNotificationInfos ?? _newNotificationInfos,
  advancePaymentInfos: advancePaymentInfos ?? _advancePaymentInfos,
  advancePaymentQrInfos: advancePaymentQrInfos ?? _advancePaymentQrInfos,
  chatInfos: chatInfos ?? _chatInfos,
  noticeInfos: noticeInfos ?? _noticeInfos,
  sharedMediaInfos: sharedMediaInfos ?? _sharedMediaInfos,
  ratingInfos: ratingInfos ?? _ratingInfos,
);
  String? get providerServiceInfo => _providerServiceInfo;
  String? get providerServiceResourcesInfo => _providerServiceResourcesInfo;
  String? get resourcesNoPerUserInfo => _resourcesNoPerUserInfo;
  String? get bookingInfos => _bookingInfos;
  String? get notificationInfos => _notificationInfos;
  String? get newNotificationInfos => _newNotificationInfos;
  String? get advancePaymentInfos => _advancePaymentInfos;
  String? get advancePaymentQrInfos => _advancePaymentQrInfos;
  String? get chatInfos => _chatInfos;
  String? get noticeInfos => _noticeInfos;
  String? get sharedMediaInfos => _sharedMediaInfos;
  String? get ratingInfos => _ratingInfos;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceInfo'] = _providerServiceInfo;
    map['providerServiceResourcesInfo'] = _providerServiceResourcesInfo;
    map['resourcesNoPerUserInfo'] = _resourcesNoPerUserInfo;
    map['bookingInfos'] = _bookingInfos;
    map['notificationInfos'] = _notificationInfos;
    map['newNotificationInfos'] = _newNotificationInfos;
    map['advancePaymentInfos'] = _advancePaymentInfos;
    map['advancePaymentQrInfos'] = _advancePaymentQrInfos;
    map['chatInfos'] = _chatInfos;
    map['noticeInfos'] = _noticeInfos;
    map['sharedMediaInfos'] = _sharedMediaInfos;
    map['ratingInfos'] = _ratingInfos;
    return map;
  }

}