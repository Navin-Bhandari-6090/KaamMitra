/// providerServiceInfo : "11&13&14"
/// providerServiceResourcesInfo : "20&21"
/// bookingInfos : ""
/// notificationInfos : "1&2&3&4&5&6&7&8&9&21&22&23&24&25&29&30&31&32&33&34&35&39&40&41&43&44&45&46&49&50&51&52&53&54&55&63&64&72&73&74&75&77&78&79&80&81&82&83&84&85&86&87&88&89&90&91&92&93&94&95&96&97&98&99&100&101&102&103&104&105&106&107&108&109&110&111&115&116&160&161&162&163&164&165&166&167"
/// newNotificationInfos : "1"
/// advancePaymentInfos : ""
/// advancePaymentQrInfos : "6"
/// chatInfos : "1&7&8&9&12&13&16&18&20&23&25&26&28&30&32&33&35&36&38&39&41&43&44&46&48&50&51&53&55&58&60&61&63&65&67&69"
/// newMessageStatusInfos : ""
/// sharedMediaInfos : "5"
/// ratingInfos : ""

class UserLinkedResoModel {
  UserLinkedResoModel({
      String? providerServiceInfo, 
      String? providerServiceResourcesInfo, 
      String? bookingInfos, 
      String? notificationInfos, 
      String? newNotificationInfos, 
      String? advancePaymentInfos, 
      String? advancePaymentQrInfos, 
      String? chatInfos, 
      String? newMessageStatusInfos, 
      String? sharedMediaInfos, 
      String? ratingInfos,}){
    _providerServiceInfo = providerServiceInfo;
    _providerServiceResourcesInfo = providerServiceResourcesInfo;
    _bookingInfos = bookingInfos;
    _notificationInfos = notificationInfos;
    _newNotificationInfos = newNotificationInfos;
    _advancePaymentInfos = advancePaymentInfos;
    _advancePaymentQrInfos = advancePaymentQrInfos;
    _chatInfos = chatInfos;
    _newMessageStatusInfos = newMessageStatusInfos;
    _sharedMediaInfos = sharedMediaInfos;
    _ratingInfos = ratingInfos;
}

  UserLinkedResoModel.fromJson(dynamic json) {
    _providerServiceInfo = json['providerServiceInfo'];
    _providerServiceResourcesInfo = json['providerServiceResourcesInfo'];
    _bookingInfos = json['bookingInfos'];
    _notificationInfos = json['notificationInfos'];
    _newNotificationInfos = json['newNotificationInfos'];
    _advancePaymentInfos = json['advancePaymentInfos'];
    _advancePaymentQrInfos = json['advancePaymentQrInfos'];
    _chatInfos = json['chatInfos'];
    _newMessageStatusInfos = json['newMessageStatusInfos'];
    _sharedMediaInfos = json['sharedMediaInfos'];
    _ratingInfos = json['ratingInfos'];
  }
  String? _providerServiceInfo;
  String? _providerServiceResourcesInfo;
  String? _bookingInfos;
  String? _notificationInfos;
  String? _newNotificationInfos;
  String? _advancePaymentInfos;
  String? _advancePaymentQrInfos;
  String? _chatInfos;
  String? _newMessageStatusInfos;
  String? _sharedMediaInfos;
  String? _ratingInfos;
UserLinkedResoModel copyWith({  String? providerServiceInfo,
  String? providerServiceResourcesInfo,
  String? bookingInfos,
  String? notificationInfos,
  String? newNotificationInfos,
  String? advancePaymentInfos,
  String? advancePaymentQrInfos,
  String? chatInfos,
  String? newMessageStatusInfos,
  String? sharedMediaInfos,
  String? ratingInfos,
}) => UserLinkedResoModel(  providerServiceInfo: providerServiceInfo ?? _providerServiceInfo,
  providerServiceResourcesInfo: providerServiceResourcesInfo ?? _providerServiceResourcesInfo,
  bookingInfos: bookingInfos ?? _bookingInfos,
  notificationInfos: notificationInfos ?? _notificationInfos,
  newNotificationInfos: newNotificationInfos ?? _newNotificationInfos,
  advancePaymentInfos: advancePaymentInfos ?? _advancePaymentInfos,
  advancePaymentQrInfos: advancePaymentQrInfos ?? _advancePaymentQrInfos,
  chatInfos: chatInfos ?? _chatInfos,
  newMessageStatusInfos: newMessageStatusInfos ?? _newMessageStatusInfos,
  sharedMediaInfos: sharedMediaInfos ?? _sharedMediaInfos,
  ratingInfos: ratingInfos ?? _ratingInfos,
);
  String? get providerServiceInfo => _providerServiceInfo;
  String? get providerServiceResourcesInfo => _providerServiceResourcesInfo;
  String? get bookingInfos => _bookingInfos;
  String? get notificationInfos => _notificationInfos;
  String? get newNotificationInfos => _newNotificationInfos;
  String? get advancePaymentInfos => _advancePaymentInfos;
  String? get advancePaymentQrInfos => _advancePaymentQrInfos;
  String? get chatInfos => _chatInfos;
  String? get newMessageStatusInfos => _newMessageStatusInfos;
  String? get sharedMediaInfos => _sharedMediaInfos;
  String? get ratingInfos => _ratingInfos;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceInfo'] = _providerServiceInfo;
    map['providerServiceResourcesInfo'] = _providerServiceResourcesInfo;
    map['bookingInfos'] = _bookingInfos;
    map['notificationInfos'] = _notificationInfos;
    map['newNotificationInfos'] = _newNotificationInfos;
    map['advancePaymentInfos'] = _advancePaymentInfos;
    map['advancePaymentQrInfos'] = _advancePaymentQrInfos;
    map['chatInfos'] = _chatInfos;
    map['newMessageStatusInfos'] = _newMessageStatusInfos;
    map['sharedMediaInfos'] = _sharedMediaInfos;
    map['ratingInfos'] = _ratingInfos;
    return map;
  }

}