/// providerServiceResourcesId : 4
/// servicePhoto : "/uploads/service-resources/photos/93c34bb762f343018a1b67bdb6516a38.png"
/// serviceVideo : "/uploads/service-resources/videos/421932f3e47f4cbeafa33ce9ea5f8f1b.mp4"
/// providerServiceId : 3
/// email : "sd2@.com"
/// userNumber : 5
/// providerServices : null
/// users : null

class ProRegServResourcesModel {
  ProRegServResourcesModel({
      num? providerServiceResourcesId, 
      String? servicePhoto, 
      String? serviceVideo, 
      num? providerServiceId, 
      String? email, 
      num? userNumber, 
      dynamic providerServices, 
      dynamic users,}){
    _providerServiceResourcesId = providerServiceResourcesId;
    _servicePhoto = servicePhoto;
    _serviceVideo = serviceVideo;
    _providerServiceId = providerServiceId;
    _email = email;
    _userNumber = userNumber;
    _providerServices = providerServices;
    _users = users;
}

  ProRegServResourcesModel.fromJson(dynamic json) {
    _providerServiceResourcesId = json['providerServiceResourcesId'];
    _servicePhoto = json['servicePhoto'];
    _serviceVideo = json['serviceVideo'];
    _providerServiceId = json['providerServiceId'];
    _email = json['email'];
    _userNumber = json['userNumber'];
    _providerServices = json['providerServices'];
    _users = json['users'];
  }
  num? _providerServiceResourcesId;
  String? _servicePhoto;
  String? _serviceVideo;
  num? _providerServiceId;
  String? _email;
  num? _userNumber;
  dynamic _providerServices;
  dynamic _users;
ProRegServResourcesModel copyWith({  num? providerServiceResourcesId,
  String? servicePhoto,
  String? serviceVideo,
  num? providerServiceId,
  String? email,
  num? userNumber,
  dynamic providerServices,
  dynamic users,
}) => ProRegServResourcesModel(  providerServiceResourcesId: providerServiceResourcesId ?? _providerServiceResourcesId,
  servicePhoto: servicePhoto ?? _servicePhoto,
  serviceVideo: serviceVideo ?? _serviceVideo,
  providerServiceId: providerServiceId ?? _providerServiceId,
  email: email ?? _email,
  userNumber: userNumber ?? _userNumber,
  providerServices: providerServices ?? _providerServices,
  users: users ?? _users,
);
  num? get providerServiceResourcesId => _providerServiceResourcesId;
  String? get servicePhoto => _servicePhoto;
  String? get serviceVideo => _serviceVideo;
  num? get providerServiceId => _providerServiceId;
  String? get email => _email;
  num? get userNumber => _userNumber;
  dynamic get providerServices => _providerServices;
  dynamic get users => _users;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceResourcesId'] = _providerServiceResourcesId;
    map['servicePhoto'] = _servicePhoto;
    map['serviceVideo'] = _serviceVideo;
    map['providerServiceId'] = _providerServiceId;
    map['email'] = _email;
    map['userNumber'] = _userNumber;
    map['providerServices'] = _providerServices;
    map['users'] = _users;
    return map;
  }

}