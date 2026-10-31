/// serviceName : "player"
/// providerServiceResourcesId : 9
/// resourceFile : ""
/// providerServiceId : 6
/// serviceTitle : ""

class ServResourFileInfoModel {
  ServResourFileInfoModel({
      String? serviceName, 
      num? providerServiceResourcesId, 
      String? resourceFile, 
      num? providerServiceId, 
      String? serviceTitle,}){
    _serviceName = serviceName;
    _providerServiceResourcesId = providerServiceResourcesId;
    _resourceFile = resourceFile;
    _providerServiceId = providerServiceId;
    _serviceTitle = serviceTitle;
}

  ServResourFileInfoModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _resourceFile = json['resourceFile'];
    _providerServiceId = json['providerServiceId'];
    _serviceTitle = json['serviceTitle'];
  }
  String? _serviceName;
  num? _providerServiceResourcesId;
  String? _resourceFile;
  num? _providerServiceId;
  String? _serviceTitle;
ServResourFileInfoModel copyWith({  String? serviceName,
  num? providerServiceResourcesId,
  String? resourceFile,
  num? providerServiceId,
  String? serviceTitle,
}) => ServResourFileInfoModel(  serviceName: serviceName ?? _serviceName,
  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  resourceFile: resourceFile ?? _resourceFile,
  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceTitle: serviceTitle ?? _serviceTitle,
);
  String? get serviceName => _serviceName;
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get resourceFile => _resourceFile;
  num? get providerServiceId => _providerServiceId;
  String? get serviceTitle => _serviceTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['resourceFile'] = _resourceFile;
    map['providerServiceId'] = _providerServiceId;
    map['serviceTitle'] = _serviceTitle;
    return map;
  }

}