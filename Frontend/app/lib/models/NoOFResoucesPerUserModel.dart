/// resourcesNumberId : 1
/// noOfRes : 5
/// serviceName : "driver"
/// userNumber : 2

class NoOfResoucesPerUserModel {
  NoOfResoucesPerUserModel({
      num? resourcesNumberId, 
      num? noOfRes, 
      String? serviceName, 
      num? userNumber,}){
    _resourcesNumberId = resourcesNumberId;
    _noOfRes = noOfRes;
    _serviceName = serviceName;
    _userNumber = userNumber;
}

  NoOfResoucesPerUserModel.fromJson(dynamic json) {
    _resourcesNumberId = json['resourcesNumberId'];
    _noOfRes = json['noOfRes'];
    _serviceName = json['serviceName'];
    _userNumber = json['userNumber'];
  }
  num? _resourcesNumberId;
  num? _noOfRes;
  String? _serviceName;
  num? _userNumber;
NoOfResoucesPerUserModel copyWith({  num? resourcesNumberId,
  num? noOfRes,
  String? serviceName,
  num? userNumber,
}) => NoOfResoucesPerUserModel(  resourcesNumberId: resourcesNumberId ?? _resourcesNumberId,
  noOfRes: noOfRes ?? _noOfRes,
  serviceName: serviceName ?? _serviceName,
  userNumber: userNumber ?? _userNumber,
);
  num? get resourcesNumberId => _resourcesNumberId;
  num? get noOfRes => _noOfRes;
  String? get serviceName => _serviceName;
  num? get userNumber => _userNumber;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['resourcesNumberId'] = _resourcesNumberId;
    map['noOfRes'] = _noOfRes;
    map['serviceName'] = _serviceName;
    map['userNumber'] = _userNumber;
    return map;
  }

}