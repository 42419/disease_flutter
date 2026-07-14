class User {
  String nickName;
  String userAvatarUrl;
  String role; // 0 for farmer, 1 for admin

  User({
    this.nickName = "",
    this.userAvatarUrl = "assets/img/avatar.jpg",
    this.role = "0",
  });
}
