/// serviceName : "player"
/// providerServiceResourcesId : 9
/// serviceVideo : "/uploads/service-resources/videos/74bbb23127244c74b6a1e26978db435c.mp4"
/// providerServiceId : 6
/// serviceTitle : ""

class ProviderSerResVideoModel {
  ProviderSerResVideoModel({
      String? serviceName, 
      num? providerServiceResourcesId, 
      String? serviceVideo, 
      num? providerServiceId, 
      String? serviceTitle,}){
    _serviceName = serviceName;
    _providerServiceResourcesId = providerServiceResourcesId;
    _serviceVideo = serviceVideo;
    _providerServiceId = providerServiceId;
    _serviceTitle = serviceTitle;
}

  ProviderSerResVideoModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _serviceVideo = json['serviceVideo'];
    _providerServiceId = json['providerServiceId'];
    _serviceTitle = json['serviceTitle'];
  }
  String? _serviceName;
  num? _providerServiceResourcesId;
  String? _serviceVideo;
  num? _providerServiceId;
  String? _serviceTitle;
ProviderSerResVideoModel copyWith({  String? serviceName,
  num? providerServiceResourcesId,
  String? serviceVideo,
  num? providerServiceId,
  String? serviceTitle,
}) => ProviderSerResVideoModel(  serviceName: serviceName ?? _serviceName,
  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  serviceVideo: serviceVideo ?? _serviceVideo,
  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceTitle: serviceTitle ?? _serviceTitle,
);
  String? get serviceName => _serviceName;
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get serviceVideo => _serviceVideo;
  num? get providerServiceId => _providerServiceId;
  String? get serviceTitle => _serviceTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['serviceVideo'] = _serviceVideo;
    map['providerServiceId'] = _providerServiceId;
    map['serviceTitle'] = _serviceTitle;
    return map;
  }

}