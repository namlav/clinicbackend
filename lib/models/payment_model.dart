class PaymentModel {
  final int paymentid;
  final int appointmentid;
  final double amount;
  final String status; // 'Pending', 'Success', 'Failed'

  PaymentModel({
    required this.paymentid,
    required this.appointmentid,
    required this.amount,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentid: json['paymentid'] as int,
      appointmentid: json['appointmentid'] as int,
      amount: (json['totalamount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentid': paymentid,
      'appointmentid': appointmentid,
      'totalamount': amount,
      'status': status,
    };
  }
}
