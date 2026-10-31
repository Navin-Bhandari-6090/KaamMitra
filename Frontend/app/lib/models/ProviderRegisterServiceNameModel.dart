/// serviceName : "hotel"
/// serviceID : 12
/// proRegServiceDescription : "vdsdsds rtuyii tybccxv"

class ProviderRegisterServiceNameModel {
  ProviderRegisterServiceNameModel({
      String? serviceName, 
      num? serviceID, 
      String? proRegServiceDescription,}){
    _serviceName = serviceName;
    _serviceID = serviceID;
    _proRegServiceDescription = proRegServiceDescription;
}

  ProviderRegisterServiceNameModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _serviceID = json['serviceID'];
    _proRegServiceDescription = json['proRegServiceDescription'];
  }
  String? _serviceName;
  num? _serviceID;
  String? _proRegServiceDescription;
ProviderRegisterServiceNameModel copyWith({  String? serviceName,
  num? serviceID,
  String? proRegServiceDescription,
}) => ProviderRegisterServiceNameModel(  serviceName: serviceName ?? _serviceName,
  serviceID: serviceID ?? _serviceID,
  proRegServiceDescription: proRegServiceDescription ?? _proRegServiceDescription,
);
  String? get serviceName => _serviceName;
  num? get serviceID => _serviceID;
  String? get proRegServiceDescription => _proRegServiceDescription;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['serviceID'] = _serviceID;
    map['proRegServiceDescription'] = _proRegServiceDescription;
    return map;
  }

}