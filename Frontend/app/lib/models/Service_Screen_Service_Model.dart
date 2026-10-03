/// providerServiceId : 1
/// serviceName : "painter"
/// serviceDocument : "/uploads/service-documents/951e2409170c46869b2bee903bc73bb8.pdf"
/// email : "sd@.com"
/// userNumber : 1

class ServiceScreenServiceModel
{
  ServiceScreenServiceModel({
      num? providerServiceId, 
      String? serviceName, 
      String? serviceDocument, 
      String? email, 
      num? userNumber,}){
    _providerServiceId = providerServiceId;
    _serviceName = serviceName;
    _serviceDocument = serviceDocument;
    _email = email;
    _userNumber = userNumber;
}

  ServiceScreenServiceModel.fromJson(dynamic json) {
    _providerServiceId = json['providerServiceId'];
    _serviceName = json['serviceName'];
    _serviceDocument = json['serviceDocument'];
    _email = json['email'];
    _userNumber = json['userNumber'];
  }
  num? _providerServiceId;
  String? _serviceName;
  String? _serviceDocument;
  String? _email;
  num? _userNumber;
ServiceScreenServiceModel copyWith({  num? providerServiceId,
  String? serviceName,
  String? serviceDocument,
  String? email,
  num? userNumber,
}) => ServiceScreenServiceModel(  providerServiceId: providerServiceId ?? _providerServiceId,
  serviceName: serviceName ?? _serviceName,
  serviceDocument: serviceDocument ?? _serviceDocument,
  email: email ?? _email,
  userNumber: userNumber ?? _userNumber,
);
  num? get providerServiceId => _providerServiceId;
  String? get serviceName => _serviceName;
  String? get serviceDocument => _serviceDocument;
  String? get email => _email;
  num? get userNumber => _userNumber;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['providerServiceId'] = _providerServiceId;
    map['serviceName'] = _serviceName;
    map['serviceDocument'] = _serviceDocument;
    map['email'] = _email;
    map['userNumber'] = _userNumber;
    return map;
  }

}