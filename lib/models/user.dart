class User {
  String nickName;
  String userAvatarUrl;
  String role; // 0 for farmer, 1 for admin

  User({
    this.nickName = "",
    this.userAvatarUrl = "https://rin-img.liyunfei.eu.org/douyin-hono-images/u1_1767694990248_p4bduq.jpg",
    this.role = "0",
  });
}
