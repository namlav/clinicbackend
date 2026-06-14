class ServiceModel {
  final int serviceid;
  final String servicename;
  final String? description;
  final double price;
  final int? specialtyid;
  final bool isActive;

  ServiceModel({
    required this.serviceid,
    required this.servicename,
    this.description,
    required this.price,
    this.specialtyid,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceid: json['serviceid'] as int,
      servicename: json['servicename'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      specialtyid: json['specialtyid'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceid': serviceid,
      'servicename': servicename,
      'description': description,
      'price': price,
      'specialtyid': specialtyid,
      'is_active': isActive,
    };
  }
}
