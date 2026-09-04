/// serviceName : "Painter"
/// providerServiceResourcesId : 1
/// serviceVideo : "/uploads/service-resources/videos/cfe4577338114c7c9d665eb3ffdf03af.mp4"
/// providerServiceId : 1

class ProviderSerResVideoModel {
  ProviderSerResVideoModel({
      String? serviceName, 
      num? providerServiceResourcesId, 
      String? serviceVideo, 
      num? providerServiceId,}){
    _serviceName = serviceName;
    _providerServiceResourcesId = providerServiceResourcesId;
    _serviceVideo = serviceVideo;
    _providerServiceId = providerServiceId;
}

  ProviderSerResVideoModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _serviceVideo = json['serviceVideo'];
    _providerServiceId = json['providerServiceId'];
  }
  String? _serviceName;
  num? _providerServiceResourcesId;
  String? _serviceVideo;
  num? _providerServiceId;
ProviderSerResVideoModel copyWith({  String? serviceName,
  num? providerServiceResourcesId,
  String? serviceVideo,
  num? providerServiceId,
}) => ProviderSerResVideoModel(  serviceName: serviceName ?? _serviceName,
  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  serviceVideo: serviceVideo ?? _serviceVideo,
  providerServiceId: providerServiceId ?? _providerServiceId,
);
  String? get serviceName => _serviceName;
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get serviceVideo => _serviceVideo;
  num? get providerServiceId => _providerServiceId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['serviceVideo'] = _serviceVideo;
    map['providerServiceId'] = _providerServiceId;
    return map;
  }

}