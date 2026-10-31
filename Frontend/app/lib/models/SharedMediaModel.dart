/// sharedMediaId : 1
/// mediaDescription : "tytyyrte"
/// servicePhoto : "/uploads/media/photos/774de4d015c748f8afe7180261e77ed6.jpg"
/// serviceVideo : ""
/// serviceFile : ""
/// createdAt : "2026-10-30T06:59:12.582095Z"
/// senderNumber : 5
/// receiverNumber : 6
/// senderName : "aaa55 aaa"
/// receiverName : "aaa 6 aaa"

class SharedMediaModel {
  SharedMediaModel({
      num? sharedMediaId, 
      String? mediaDescription, 
      String? servicePhoto, 
      String? serviceVideo, 
      String? serviceFile, 
      String? createdAt, 
      num? senderNumber, 
      num? receiverNumber, 
      String? senderName, 
      String? receiverName,}){
    _sharedMediaId = sharedMediaId;
    _mediaDescription = mediaDescription;
    _servicePhoto = servicePhoto;
    _serviceVideo = serviceVideo;
    _serviceFile = serviceFile;
    _createdAt = createdAt;
    _senderNumber = senderNumber;
    _receiverNumber = receiverNumber;
    _senderName = senderName;
    _receiverName = receiverName;
}

  SharedMediaModel.fromJson(dynamic json) {
    _sharedMediaId = json['sharedMediaId'];
    _mediaDescription = json['mediaDescription'];
    _servicePhoto = json['servicePhoto'];
    _serviceVideo = json['serviceVideo'];
    _serviceFile = json['serviceFile'];
    _createdAt = json['createdAt'];
    _senderNumber = json['senderNumber'];
    _receiverNumber = json['receiverNumber'];
    _senderName = json['senderName'];
    _receiverName = json['receiverName'];
  }
  num? _sharedMediaId;
  String? _mediaDescription;
  String? _servicePhoto;
  String? _serviceVideo;
  String? _serviceFile;
  String? _createdAt;
  num? _senderNumber;
  num? _receiverNumber;
  String? _senderName;
  String? _receiverName;
SharedMediaModel copyWith({  num? sharedMediaId,
  String? mediaDescription,
  String? servicePhoto,
  String? serviceVideo,
  String? serviceFile,
  String? createdAt,
  num? senderNumber,
  num? receiverNumber,
  String? senderName,
  String? receiverName,
}) => SharedMediaModel(  sharedMediaId: sharedMediaId ?? _sharedMediaId,
  mediaDescription: mediaDescription ?? _mediaDescription,
  servicePhoto: servicePhoto ?? _servicePhoto,
  serviceVideo: serviceVideo ?? _serviceVideo,
  serviceFile: serviceFile ?? _serviceFile,
  createdAt: createdAt ?? _createdAt,
  senderNumber: senderNumber ?? _senderNumber,
  receiverNumber: receiverNumber ?? _receiverNumber,
  senderName: senderName ?? _senderName,
  receiverName: receiverName ?? _receiverName,
);
  num? get sharedMediaId => _sharedMediaId;
  String? get mediaDescription => _mediaDescription;
  String? get servicePhoto => _servicePhoto;
  String? get serviceVideo => _serviceVideo;
  String? get serviceFile => _serviceFile;
  String? get createdAt => _createdAt;
  num? get senderNumber => _senderNumber;
  num? get receiverNumber => _receiverNumber;
  String? get senderName => _senderName;
  String? get receiverName => _receiverName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['sharedMediaId'] = _sharedMediaId;
    map['mediaDescription'] = _mediaDescription;
    map['servicePhoto'] = _servicePhoto;
    map['serviceVideo'] = _serviceVideo;
    map['serviceFile'] = _serviceFile;
    map['createdAt'] = _createdAt;
    map['senderNumber'] = _senderNumber;
    map['receiverNumber'] = _receiverNumber;
    map['senderName'] = _senderName;
    map['receiverName'] = _receiverName;
    return map;
  }

}