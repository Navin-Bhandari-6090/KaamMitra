/// userEmail : "sd@.com"
/// serviceName : "painter"
/// averageRating : 2

class RatingInfoModel {
  RatingInfoModel({
      String? userEmail, 
      String? serviceName, 
      num? averageRating,}){
    _userEmail = userEmail;
    _serviceName = serviceName;
    _averageRating = averageRating;
}

  RatingInfoModel.fromJson(dynamic json) {
    _userEmail = json['userEmail'];
    _serviceName = json['serviceName'];
    _averageRating = json['averageRating'];
  }
  String? _userEmail;
  String? _serviceName;
  num? _averageRating;
RatingInfoModel copyWith({  String? userEmail,
  String? serviceName,
  num? averageRating,
}) => RatingInfoModel(  userEmail: userEmail ?? _userEmail,
  serviceName: serviceName ?? _serviceName,
  averageRating: averageRating ?? _averageRating,
);
  String? get userEmail => _userEmail;
  String? get serviceName => _serviceName;
  num? get averageRating => _averageRating;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userEmail'] = _userEmail;
    map['serviceName'] = _serviceName;
    map['averageRating'] = _averageRating;
    return map;
  }

}