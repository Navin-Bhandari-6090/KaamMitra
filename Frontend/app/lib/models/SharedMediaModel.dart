/// sharedMediaId : 2
/// mediaDescription : "fds fsdf fssd"
/// servicePhoto : "/uploads/media/photos/8d3344825f014d6a8d5606ef6881e67c.png"
/// serviceVideo : "/uploads/media/videos/b49d5e0d621a451c8a3d0ddcbfc460ce.mp4"
/// serviceFile : ""
/// createdAt : "2026-11-10T08:15:32.319254Z"
/// senderNumber : 2
/// receiverNumber : 1
/// senderName : "vdgfdgdf gfdgfgfd"
/// receiverName : "gdfggdf dfgdgf"
/// senderPhoto : ""
/// receiverPhoto : ""

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
      String? receiverName, 
      String? senderPhoto, 
      String? receiverPhoto,}){
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
    _senderPhoto = senderPhoto;
    _receiverPhoto = receiverPhoto;
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
    _senderPhoto = json['senderPhoto'];
    _receiverPhoto = json['receiverPhoto'];
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
  String? _senderPhoto;
  String? _receiverPhoto;
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
  String? senderPhoto,
  String? receiverPhoto,
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
  senderPhoto: senderPhoto ?? _senderPhoto,
  receiverPhoto: receiverPhoto ?? _receiverPhoto,
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
  String? get senderPhoto => _senderPhoto;
  String? get receiverPhoto => _receiverPhoto;

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
    map['senderPhoto'] = _senderPhoto;
    map['receiverPhoto'] = _receiverPhoto;
    return map;
  }

}