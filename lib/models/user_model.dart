class UserModel {
  final int userid;
  final String? authid;
  final String fullname;
  final String? phone;
  final String? email;
  final String role; // 'patient', 'doctor', 'admin'
  final bool isactive;

  UserModel({
    required this.userid,
    this.authid,
    required this.fullname,
    this.phone,
    this.email,
    required this.role,
    required this.isactive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userid: json['userid'] as int,
      authid: json['authid'] as String?,
      fullname: json['fullname'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'patient',
      isactive: json['isactive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'authid': authid,
      'fullname': fullname,
      'phone': phone,
      'email': email,
      'role': role,
      'isactive': isactive,
    };
  }
}
