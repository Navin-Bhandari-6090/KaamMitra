/// advertisementId : 4
/// photo : "/uploads/advertisements/photos/879e0d12-e7c3-4136-b7de-4bfe9cc00460.jpg"
/// video : "/uploads/advertisements/videos/ad5bf984-2faa-4dbb-a9d2-5c30fb5e1d1c.mp4"
/// tittle : "fwfwfs"
/// urlLink : "dsdsffds"
/// uploadedAt : "2026-09-30T16:53:34.362897Z"

class AdvertisementInfoModel {
  AdvertisementInfoModel({
      num? advertisementId, 
      String? photo, 
      String? video, 
      String? tittle, 
      String? urlLink, 
      String? uploadedAt,}){
    _advertisementId = advertisementId;
    _photo = photo;
    _video = video;
    _tittle = tittle;
    _urlLink = urlLink;
    _uploadedAt = uploadedAt;
}

  AdvertisementInfoModel.fromJson(dynamic json) {
    _advertisementId = json['advertisementId'];
    _photo = json['photo'];
    _video = json['video'];
    _tittle = json['tittle'];
    _urlLink = json['urlLink'];
    _uploadedAt = json['uploadedAt'];
  }
  num? _advertisementId;
  String? _photo;
  String? _video;
  String? _tittle;
  String? _urlLink;
  String? _uploadedAt;
AdvertisementInfoModel copyWith({  num? advertisementId,
  String? photo,
  String? video,
  String? tittle,
  String? urlLink,
  String? uploadedAt,
}) => AdvertisementInfoModel(  advertisementId: advertisementId ?? _advertisementId,
  photo: photo ?? _photo,
  video: video ?? _video,
  tittle: tittle ?? _tittle,
  urlLink: urlLink ?? _urlLink,
  uploadedAt: uploadedAt ?? _uploadedAt,
);
  num? get advertisementId => _advertisementId;
  String? get photo => _photo;
  String? get video => _video;
  String? get tittle => _tittle;
  String? get urlLink => _urlLink;
  String? get uploadedAt => _uploadedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['advertisementId'] = _advertisementId;
    map['photo'] = _photo;
    map['video'] = _video;
    map['tittle'] = _tittle;
    map['urlLink'] = _urlLink;
    map['uploadedAt'] = _uploadedAt;
    return map;
  }

}