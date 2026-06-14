class DoctorModel {
  final int doctorid;
  final int userid;
  final String fullname;
  final int? specialtyid;
  final String? avatarurl;
  final String? bio;
  final int? experienceyears;

  DoctorModel({
    required this.doctorid,
    required this.userid,
    required this.fullname,
    this.specialtyid,
    this.avatarurl,
    this.bio,
    this.experienceyears,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      doctorid: json['doctorid'] as int,
      userid: json['userid'] as int,
      fullname: json['fullname'] as String? ?? '',
      specialtyid: json['specialtyid'] as int?,
      avatarurl: json['avatarurl'] as String?,
      bio: json['bio'] as String?,
      experienceyears: json['experienceyears'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorid': doctorid,
      'userid': userid,
      'fullname': fullname,
      'specialtyid': specialtyid,
      'avatarurl': avatarurl,
      'bio': bio,
      'experienceyears': experienceyears,
    };
  }
}
