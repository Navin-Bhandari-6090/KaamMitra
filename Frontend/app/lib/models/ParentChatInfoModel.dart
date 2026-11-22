import 'ChatInfoModel.dart';

class ChatMessagesResponseModel {
  ChatMessagesResponseModel({
    String? currentUserPhoto,
    String? otherUserPhoto,
    List<ChatInfoModel>? chatMessages,
  }) {
    _currentUserPhoto = currentUserPhoto;
    _otherUserPhoto = otherUserPhoto;
    _chatMessages = chatMessages;
  }

  ChatMessagesResponseModel.fromJson(dynamic json) {
    _currentUserPhoto = json['currentUserPhoto'];
    _otherUserPhoto = json['otherUserPhoto'];

    if (json['chatMessages'] != null) {
      _chatMessages = [];

      json['chatMessages'].forEach((v) {
        _chatMessages!.add(ChatInfoModel.fromJson(v));
      });
    }
  }

  String? _currentUserPhoto;
  String? _otherUserPhoto;
  List<ChatInfoModel>? _chatMessages;

  String? get currentUserPhoto => _currentUserPhoto;
  String? get otherUserPhoto => _otherUserPhoto;
  List<ChatInfoModel>? get chatMessages => _chatMessages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['currentUserPhoto'] = _currentUserPhoto;
    map['otherUserPhoto'] = _otherUserPhoto;
    map['chatMessages'] =
        _chatMessages?.map((v) => v.toJson()).toList();
    return map;
  }
}