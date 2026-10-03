/// ratingReceiverNumber : 5
/// serviceName : "plumber"
/// averageRating : 5

class RatingInfoModel {
  RatingInfoModel({
      num? ratingReceiverNumber, 
      String? serviceName, 
      num? averageRating,}){
    _ratingReceiverNumber = ratingReceiverNumber;
    _serviceName = serviceName;
    _averageRating = averageRating;
}

  RatingInfoModel.fromJson(dynamic json) {
    _ratingReceiverNumber = json['ratingReceiverNumber'];
    _serviceName = json['serviceName'];
    _averageRating = json['averageRating'];
  }
  num? _ratingReceiverNumber;
  String? _serviceName;
  num? _averageRating;
RatingInfoModel copyWith({  num? ratingReceiverNumber,
  String? serviceName,
  num? averageRating,
}) => RatingInfoModel(  ratingReceiverNumber: ratingReceiverNumber ?? _ratingReceiverNumber,
  serviceName: serviceName ?? _serviceName,
  averageRating: averageRating ?? _averageRating,
);
  num? get ratingReceiverNumber => _ratingReceiverNumber;
  String? get serviceName => _serviceName;
  num? get averageRating => _averageRating;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ratingReceiverNumber'] = _ratingReceiverNumber;
    map['serviceName'] = _serviceName;
    map['averageRating'] = _averageRating;
    return map;
  }

}