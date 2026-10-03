/// serviceName : "plumber"
/// serviceID : 1

class ProviderRegisterServiceNameModel {
  ProviderRegisterServiceNameModel({
      String? serviceName, 
      num? serviceID,}){
    _serviceName = serviceName;
    _serviceID = serviceID;
}

  ProviderRegisterServiceNameModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _serviceID = json['serviceID'];
  }
  String? _serviceName;
  num? _serviceID;
ProviderRegisterServiceNameModel copyWith({  String? serviceName,
  num? serviceID,
}) => ProviderRegisterServiceNameModel(  serviceName: serviceName ?? _serviceName,
  serviceID: serviceID ?? _serviceID,
);
  String? get serviceName => _serviceName;
  num? get serviceID => _serviceID;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['serviceID'] = _serviceID;
    return map;
  }

}