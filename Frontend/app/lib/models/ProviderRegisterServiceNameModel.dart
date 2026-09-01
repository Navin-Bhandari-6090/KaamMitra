/// serviceName : "Painter"

class ProviderRegisterServiceNameModel {
  ProviderRegisterServiceNameModel({
      String? serviceName,}){
    _serviceName = serviceName;
}

  ProviderRegisterServiceNameModel.fromJson(dynamic json) {
    _serviceName = json['serviceName'];
  }
  String? _serviceName;
ProviderRegisterServiceNameModel copyWith({  String? serviceName,
}) => ProviderRegisterServiceNameModel(  serviceName: serviceName ?? _serviceName,
);
  String? get serviceName => _serviceName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['serviceName'] = _serviceName;
    return map;
  }

}