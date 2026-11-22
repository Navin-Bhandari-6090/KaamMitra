
/// userNumber : 2
/// firstName : "Navin"
/// lastName : "Bhandari"
/// fullName : "Navin Bhandari"
/// email : "navin@example.com"
/// photo : "uploads/profile/photo.png"
/// hasChatted : true
/// lastMessage : "Hello"
/// lastMessageAt : "2026-11-09T18:17:37.2495Z"
/// unreadCount : 2

class ChatListUserModel {
  ChatListUserModel({
    num? userNumber,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? photo,
    bool? hasChatted,
    String? lastMessage,
    String? lastMessageAt,
    num? unreadCount,
  }) {
    _userNumber = userNumber;
    _firstName = firstName;
    _lastName = lastName;
    _fullName = fullName;
    _email = email;
    _photo = photo;
    _hasChatted = hasChatted;
    _lastMessage = lastMessage;
    _lastMessageAt = lastMessageAt;
    _unreadCount = unreadCount;
  }

  ChatListUserModel.fromJson(dynamic json) {
    _userNumber = _toNum(json?['userNumber']);
    _firstName = json?['firstName']?.toString() ?? '';
    _lastName = json?['lastName']?.toString() ?? '';
    _fullName = json?['fullName']?.toString() ?? '';
    _email = json?['email']?.toString() ?? '';
    _photo = json?['photo']?.toString();
    _hasChatted = _toBool(json?['hasChatted']);
    _lastMessage = json?['lastMessage']?.toString();
    _lastMessageAt = json?['lastMessageAt']?.toString();
    _unreadCount = _toNum(json?['unreadCount']);
  }

  num? _userNumber;
  String? _firstName;
  String? _lastName;
  String? _fullName;
  String? _email;
  String? _photo;
  bool? _hasChatted;
  String? _lastMessage;
  String? _lastMessageAt;
  num? _unreadCount;

  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();

    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;

    return null;
  }

  ChatListUserModel copyWith({
    num? userNumber,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? photo,
    bool? hasChatted,
    String? lastMessage,
    String? lastMessageAt,
    num? unreadCount,
  }) =>
      ChatListUserModel(
        userNumber: userNumber ?? _userNumber,
        firstName: firstName ?? _firstName,
        lastName: lastName ?? _lastName,
        fullName: fullName ?? _fullName,
        email: email ?? _email,
        photo: photo ?? _photo,
        hasChatted: hasChatted ?? _hasChatted,
        lastMessage: lastMessage ?? _lastMessage,
        lastMessageAt: lastMessageAt ?? _lastMessageAt,
        unreadCount: unreadCount ?? _unreadCount,
      );

  num? get userNumber => _userNumber;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get photo => _photo;
  bool? get hasChatted => _hasChatted;
  String? get lastMessage => _lastMessage;
  String? get lastMessageAt => _lastMessageAt;
  num? get unreadCount => _unreadCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userNumber'] = _userNumber;
    map['firstName'] = _firstName;
    map['lastName'] = _lastName;
    map['fullName'] = _fullName;
    map['email'] = _email;
    map['photo'] = _photo;
    map['hasChatted'] = _hasChatted;
    map['lastMessage'] = _lastMessage;
    map['lastMessageAt'] = _lastMessageAt;
    map['unreadCount'] = _unreadCount;
    return map;
  }
}
