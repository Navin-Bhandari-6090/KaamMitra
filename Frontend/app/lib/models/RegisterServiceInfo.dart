/// serviceId : 1
/// serviceName : "Painter"
/// serviceDescription : "Person who paints houses, buildings, walls and other surfaces."

class RegisterServiceInfo {
  RegisterServiceInfo({
      num? serviceId,
      String? serviceName,
      String? serviceDescription,}){
    _serviceId = serviceId;
    _serviceName = serviceName;
    _serviceDescription = serviceDescription;
}

  RegisterServiceInfo.fromJson(dynamic json) {
    _serviceId = json['serviceId'];
    _serviceName = json['serviceName'];
    _serviceDescription = json['serviceDescription'];
  }
  num? _serviceId;
  String? _serviceName;
  String? _serviceDescription;
RegisterServiceInfo copyWith({  num? serviceId,
  String? serviceName,
  String? serviceDescription,
}) => RegisterServiceInfo(  serviceId: serviceId ?? _serviceId,
  serviceName: serviceName ?? _serviceName,
  serviceDescription: serviceDescription ?? _serviceDescription,
);
  num? get serviceId => _serviceId;
  String? get serviceName => _serviceName;
  String? get serviceDescription => _serviceDescription;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceId'] = _serviceId;
    map['serviceName'] = _serviceName;
    map['serviceDescription'] = _serviceDescription;
    return map;
  }

}