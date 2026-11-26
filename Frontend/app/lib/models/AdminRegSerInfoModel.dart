/// serviceId : 1
/// serviceName : "driver"
/// serviceDescription : "gjdflgfg;g"
/// domesticPrice : 200
/// domesticPriceDiscount : 23
/// internationalPrice : 23
/// internationalPriceDiscount : 34
/// noOfRes : 0

class AdminRegSerInfoModel {
  AdminRegSerInfoModel({
      num? serviceId, 
      String? serviceName, 
      String? serviceDescription, 
      num? domesticPrice, 
      num? domesticPriceDiscount, 
      num? internationalPrice, 
      num? internationalPriceDiscount, 
      num? noOfRes,}){
    _serviceId = serviceId;
    _serviceName = serviceName;
    _serviceDescription = serviceDescription;
    _domesticPrice = domesticPrice;
    _domesticPriceDiscount = domesticPriceDiscount;
    _internationalPrice = internationalPrice;
    _internationalPriceDiscount = internationalPriceDiscount;
    _noOfRes = noOfRes;
}

  AdminRegSerInfoModel.fromJson(dynamic json) {
    _serviceId = json['serviceId'];
    _serviceName = json['serviceName'];
    _serviceDescription = json['serviceDescription'];
    _domesticPrice = json['domesticPrice'];
    _domesticPriceDiscount = json['domesticPriceDiscount'];
    _internationalPrice = json['internationalPrice'];
    _internationalPriceDiscount = json['internationalPriceDiscount'];
    _noOfRes = json['noOfRes'];
  }
  num? _serviceId;
  String? _serviceName;
  String? _serviceDescription;
  num? _domesticPrice;
  num? _domesticPriceDiscount;
  num? _internationalPrice;
  num? _internationalPriceDiscount;
  num? _noOfRes;
AdminRegSerInfoModel copyWith({  num? serviceId,
  String? serviceName,
  String? serviceDescription,
  num? domesticPrice,
  num? domesticPriceDiscount,
  num? internationalPrice,
  num? internationalPriceDiscount,
  num? noOfRes,
}) => AdminRegSerInfoModel(  serviceId: serviceId ?? _serviceId,
  serviceName: serviceName ?? _serviceName,
  serviceDescription: serviceDescription ?? _serviceDescription,
  domesticPrice: domesticPrice ?? _domesticPrice,
  domesticPriceDiscount: domesticPriceDiscount ?? _domesticPriceDiscount,
  internationalPrice: internationalPrice ?? _internationalPrice,
  internationalPriceDiscount: internationalPriceDiscount ?? _internationalPriceDiscount,
  noOfRes: noOfRes ?? _noOfRes,
);
  num? get serviceId => _serviceId;
  String? get serviceName => _serviceName;
  String? get serviceDescription => _serviceDescription;
  num? get domesticPrice => _domesticPrice;
  num? get domesticPriceDiscount => _domesticPriceDiscount;
  num? get internationalPrice => _internationalPrice;
  num? get internationalPriceDiscount => _internationalPriceDiscount;
  num? get noOfRes => _noOfRes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceId'] = _serviceId;
    map['serviceName'] = _serviceName;
    map['serviceDescription'] = _serviceDescription;
    map['domesticPrice'] = _domesticPrice;
    map['domesticPriceDiscount'] = _domesticPriceDiscount;
    map['internationalPrice'] = _internationalPrice;
    map['internationalPriceDiscount'] = _internationalPriceDiscount;
    map['noOfRes'] = _noOfRes;
    return map;
  }

}