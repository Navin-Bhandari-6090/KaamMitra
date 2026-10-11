/// providerServiceId : 6
/// serviceName : "player"
/// serviceDocument : "/uploads/service-documents/ec253c145a154492b5942548245b2df0.pdf"
/// email : "sd2@.com"
/// userNumber : 5
/// proRegServiceDescription : "sdgsdfdds"

class ServiceScreenServiceModel {
  ServiceScreenServiceModel({
      num? providerServiceId, 
      String? serviceName, 
      String? serviceDocument, 
      String? email, 
      num? userNumber, 
      String? proRegServiceDescription,}){
    _providerServiceId = providerServiceId;
    _serviceName = serviceName;
    _serviceDocument = serviceDocument;
    _email = email;
    _userNumber = userNumber;
    _proRegServiceDescription = proRegServiceDescription;
}

  ServiceScreenServiceModel.fromJson(dynamic json) {
    _providerServiceId = json['providerServiceId'];
    _serviceName = json['serviceName'];
    _serviceDocument = json['serviceDocument'];
    _email = json['email'];
    _userNumber = json['userNumber'];
    _proRegServiceDescription = json['proRegServiceDescription'];
  }
  num? _providerServiceId;
  String? _serviceName;
  String? _serviceDocument;
  String? _email;
  num? _userNumber;
  String? _proRegServiceDescription;
ServiceScreenServiceModel copyWith({  num? providerServiceId,
  String? serviceName,
  String? serviceDocument,
  String? email,
  num? userNumber,
  String? proRegServiceDescription,
}) => ServiceScreenServiceModel(  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceName: serviceName ?? _serviceName,
  serviceDocument: serviceDocument ?? _serviceDocument,
  email: email ?? _email,
  userNumber: userNumber ?? _userNumber,
  proRegServiceDescription: proRegServiceDescription ?? _proRegServiceDescription,
);
  num? get providerServiceId => _providerServiceId;
  String? get serviceName => _serviceName;
  String? get serviceDocument => _serviceDocument;
  String? get email => _email;
  num? get userNumber => _userNumber;
  String? get proRegServiceDescription => _proRegServiceDescription;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceId'] = _providerServiceId;
    map['serviceName'] = _serviceName;
    map['serviceDocument'] = _serviceDocument;
    map['email'] = _email;
    map['userNumber'] = _userNumber;
    map['proRegServiceDescription'] = _proRegServiceDescription;
    return map;
  }

}