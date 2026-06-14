class AppointmentModel {
  final int appointmentid;
  final int userid;
  final int doctorid;
  final int? serviceid;
  final String appointmentdate; // date as 'YYYY-MM-DD'
  final String starttime; // time as 'HH:MM:SS'
  final String status; // 'Pending', 'Confirmed', 'Cancelled', 'Completed'

  AppointmentModel({
    required this.appointmentid,
    required this.userid,
    required this.doctorid,
    this.serviceid,
    required this.appointmentdate,
    required this.starttime,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentid: json['appointmentid'] as int,
      userid: json['userid'] as int,
      doctorid: json['doctorid'] as int,
      serviceid: json['serviceid'] as int?,
      appointmentdate: json['appointmentdate'] as String? ?? '',
      starttime: json['starttime'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentid': appointmentid,
      'userid': userid,
      'doctorid': doctorid,
      'serviceid': serviceid,
      'appointmentdate': appointmentdate,
      'starttime': starttime,
      'status': status,
    };
  }
}
