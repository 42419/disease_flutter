import 'package:flutter/foundation.dart';
import 'package:farm_flutter/models/user.dart';

class UserProvider extends ChangeNotifier {
  final User _user = User();

  String get nickName => _user.nickName;
  String get role => _user.role;
  String get userAvatarUrl => _user.userAvatarUrl;
  bool get isAdmin => _user.role == '1';

  void login(String nickName, String role) {
    _user.nickName = nickName;
    _user.role = role;
    notifyListeners();
  }

  void clear() {
    _user.nickName = "";
    _user.role = "0";
    _user.userAvatarUrl = "assets/img/avatar.jpg";
    notifyListeners();
  }
}
