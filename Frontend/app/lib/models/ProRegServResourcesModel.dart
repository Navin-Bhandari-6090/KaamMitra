/// providerServiceResourcesId : 11
/// serviceTitle : "qqqqq"
/// servicePhoto : ""
/// serviceVideo : ""
/// serviceFile : "/uploads/service-resources/files/5ccc1169365d460da33e7bbf6ac9ee9f.pdf"
/// providerServiceId : 6
/// userNumber : 5

class ProRegServResourcesModel {
  ProRegServResourcesModel({
      num? providerServiceResourcesId, 
      String? serviceTitle, 
      String? servicePhoto, 
      String? serviceVideo, 
      String? serviceFile, 
      num? providerServiceId, 
      num? userNumber,}){
    _providerServiceResourcesId = providerServiceResourcesId;
    _serviceTitle = serviceTitle;
    _servicePhoto = servicePhoto;
    _serviceVideo = serviceVideo;
    _serviceFile = serviceFile;
    _providerServiceId = providerServiceId;
    _userNumber = userNumber;
}

  ProRegServResourcesModel.fromJson(dynamic json) {
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _serviceTitle = json['serviceTitle'];
    _servicePhoto = json['servicePhoto'];
    _serviceVideo = json['serviceVideo'];
    _serviceFile = json['serviceFile'];
    _providerServiceId = json['providerServiceId'];
    _userNumber = json['userNumber'];
  }
  num? _providerServiceResourcesId;
  String? _serviceTitle;
  String? _servicePhoto;
  String? _serviceVideo;
  String? _serviceFile;
  num? _providerServiceId;
  num? _userNumber;
ProRegServResourcesModel copyWith({  num? providerServiceResourcesId,
  String? serviceTitle,
  String? servicePhoto,
  String? serviceVideo,
  String? serviceFile,
  num? providerServiceId,
  num? userNumber,
}) => ProRegServResourcesModel(  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  serviceTitle: serviceTitle ?? _serviceTitle,
  servicePhoto: servicePhoto ?? _servicePhoto,
  serviceVideo: serviceVideo ?? _serviceVideo,
  serviceFile: serviceFile ?? _serviceFile,
  providerServiceId: providerServiceId ?? _providerServiceId,
  userNumber: userNumber ?? _userNumber,
);
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get serviceTitle => _serviceTitle;
  String? get servicePhoto => _servicePhoto;
  String? get serviceVideo => _serviceVideo;
  String? get serviceFile => _serviceFile;
  num? get providerServiceId => _providerServiceId;
  num? get userNumber => _userNumber;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['serviceTitle'] = _serviceTitle;
    map['servicePhoto'] = _servicePhoto;
    map['serviceVideo'] = _serviceVideo;
    map['serviceFile'] = _serviceFile;
    map['providerServiceId'] = _providerServiceId;
    map['userNumber'] = _userNumber;
    return map;
  }

}