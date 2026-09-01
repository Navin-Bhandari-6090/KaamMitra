/// serviceName : "Painter"
/// providerServiceResourcesId : 10
/// servicePhoto : "bdfdfdfddfdfbbdfdbf"
/// providerServiceId : 1

class ServicePhotoModel {
  ServicePhotoModel({
      String? serviceName, 
      num? providerServiceResourcesId, 
      String? servicePhoto, 
      num? providerServiceId,}){
    _serviceName = serviceName;
    _providerServiceResourcesId = providerServiceResourcesId;
    _servicePhoto = servicePhoto;
    _providerServiceId = providerServiceId;
}

  ServicePhotoModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _servicePhoto = json['servicePhoto'];
    _providerServiceId = json['providerServiceId'];
  }
  String? _serviceName;
  num? _providerServiceResourcesId;
  String? _servicePhoto;
  num? _providerServiceId;
ServicePhotoModel copyWith({  String? serviceName,
  num? providerServiceResourcesId,
  String? servicePhoto,
  num? providerServiceId,
}) => ServicePhotoModel(  serviceName: serviceName ?? _serviceName,
  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  servicePhoto: servicePhoto ?? _servicePhoto,
  providerServiceId: providerServiceId ?? _providerServiceId,
);
  String? get serviceName => _serviceName;
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get servicePhoto => _servicePhoto;
  num? get providerServiceId => _providerServiceId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['servicePhoto'] = _servicePhoto;
    map['providerServiceId'] = _providerServiceId;
    return map;
  }

}