/// serviceName : "player"
/// providerServiceResourcesId : 9
/// servicePhoto : "/uploads/service-resources/photos/4c5e454e83034378baf80a48bc68bf65.jpg"
/// providerServiceId : 6
/// serviceTitle : ""

class ServicePhotoModel {
  ServicePhotoModel({
      String? serviceName, 
      num? providerServiceResourcesId, 
      String? servicePhoto, 
      num? providerServiceId, 
      String? serviceTitle,}){
    _serviceName = serviceName;
    _providerServiceResourcesId = providerServiceResourcesId;
    _servicePhoto = servicePhoto;
    _providerServiceId = providerServiceId;
    _serviceTitle = serviceTitle;
}

  ServicePhotoModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _servicePhoto = json['servicePhoto'];
    _providerServiceId = json['providerServiceId'];
    _serviceTitle = json['serviceTitle'];
  }
  String? _serviceName;
  num? _providerServiceResourcesId;
  String? _servicePhoto;
  num? _providerServiceId;
  String? _serviceTitle;
ServicePhotoModel copyWith({  String? serviceName,
  num? providerServiceResourcesId,
  String? servicePhoto,
  num? providerServiceId,
  String? serviceTitle,
}) => ServicePhotoModel(  serviceName: serviceName ?? _serviceName,
  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  servicePhoto: servicePhoto ?? _servicePhoto,
  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceTitle: serviceTitle ?? _serviceTitle,
);
  String? get serviceName => _serviceName;
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get servicePhoto => _servicePhoto;
  num? get providerServiceId => _providerServiceId;
  String? get serviceTitle => _serviceTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['servicePhoto'] = _servicePhoto;
    map['providerServiceId'] = _providerServiceId;
    map['serviceTitle'] = _serviceTitle;
    return map;
  }

}