/// providerServiceId : 1
/// serviceName : "Painter"
/// serviceDocument : "nVjdEVsZ"



class ProviderServiceFileModel {
  ProviderServiceFileModel({
      num? providerServiceId, 
      String? serviceName, 
      String? serviceDocument,}){
    _providerServiceId = providerServiceId;
    _serviceName = serviceName;
    _serviceDocument = serviceDocument;
}

  ProviderServiceFileModel.fromJson(dynamic json) {
    _providerServiceId = json['providerServiceId'];
    _serviceName = json['serviceName'];
    _serviceDocument = json['serviceDocument'];
  }
  num? _providerServiceId;
  String? _serviceName;
  String? _serviceDocument;
ProviderServiceFileModel copyWith({  num? providerServiceId,
  String? serviceName,
  String? serviceDocument,
}) => ProviderServiceFileModel(  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceName: serviceName ?? _serviceName,
  serviceDocument: serviceDocument ?? _serviceDocument,
);
  num? get providerServiceId => _providerServiceId;
  String? get serviceName => _serviceName;
  String? get serviceDocument => _serviceDocument;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceId'] = _providerServiceId;
    map['serviceName'] = _serviceName;
    map['serviceDocument'] = _serviceDocument;
    return map;
  }

}