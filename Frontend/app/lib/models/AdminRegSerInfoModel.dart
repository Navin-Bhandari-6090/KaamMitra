/// serviceId : 1
/// serviceName : "plumber"
/// serviceDescription : "ddffd"
/// domesticPrice : 56
/// domesticPriceDiscount : 3
/// internationalPrice : 5445
/// internationalPriceDiscount : 3

class AdminRegSerInfoModel {
  AdminRegSerInfoModel({
      num? serviceId, 
      String? serviceName, 
      String? serviceDescription, 
      num? domesticPrice, 
      num? domesticPriceDiscount, 
      num? internationalPrice, 
      num? internationalPriceDiscount,}){
    _serviceId = serviceId;
    _serviceName = serviceName;
    _serviceDescription = serviceDescription;
    _domesticPrice = domesticPrice;
    _domesticPriceDiscount = domesticPriceDiscount;
    _internationalPrice = internationalPrice;
    _internationalPriceDiscount = internationalPriceDiscount;
}

  AdminRegSerInfoModel.fromJson(dynamic json) {
    _serviceId = json['serviceId'];
    _serviceName = json['serviceName'];
    _serviceDescription = json['serviceDescription'];
    _domesticPrice = json['domesticPrice'];
    _domesticPriceDiscount = json['domesticPriceDiscount'];
    _internationalPrice = json['internationalPrice'];
    _internationalPriceDiscount = json['internationalPriceDiscount'];
  }
  num? _serviceId;
  String? _serviceName;
  String? _serviceDescription;
  num? _domesticPrice;
  num? _domesticPriceDiscount;
  num? _internationalPrice;
  num? _internationalPriceDiscount;
AdminRegSerInfoModel copyWith({  num? serviceId,
  String? serviceName,
  String? serviceDescription,
  num? domesticPrice,
  num? domesticPriceDiscount,
  num? internationalPrice,
  num? internationalPriceDiscount,
}) => AdminRegSerInfoModel(  serviceId: serviceId ?? _serviceId,
  serviceName: serviceName ?? _serviceName,
  serviceDescription: serviceDescription ?? _serviceDescription,
  domesticPrice: domesticPrice ?? _domesticPrice,
  domesticPriceDiscount: domesticPriceDiscount ?? _domesticPriceDiscount,
  internationalPrice: internationalPrice ?? _internationalPrice,
  internationalPriceDiscount: internationalPriceDiscount ?? _internationalPriceDiscount,
);
  num? get serviceId => _serviceId;
  String? get serviceName => _serviceName;
  String? get serviceDescription => _serviceDescription;
  num? get domesticPrice => _domesticPrice;
  num? get domesticPriceDiscount => _domesticPriceDiscount;
  num? get internationalPrice => _internationalPrice;
  num? get internationalPriceDiscount => _internationalPriceDiscount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceId'] = _serviceId;
    map['serviceName'] = _serviceName;
    map['serviceDescription'] = _serviceDescription;
    map['domesticPrice'] = _domesticPrice;
    map['domesticPriceDiscount'] = _domesticPriceDiscount;
    map['internationalPrice'] = _internationalPrice;
    map['internationalPriceDiscount'] = _internationalPriceDiscount;
    return map;
  }

}