import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String jobId;
  final String driverId;
  final double totalPrice;
  final String status; // pending | accepted | rejected
  final DateTime createdAt;

  const OfferModel({
    required this.id,
    required this.jobId,
    required this.driverId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  double get commission => totalPrice * 0.12;
  double get driverEarns => totalPrice; // cash from client

  factory OfferModel.fromMap(Map<String, dynamic> map, String id) {
    return OfferModel(
      id: id,
      jobId: map['jobId'] ?? '',
      driverId: map['driverId'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'driverId': driverId,
    'totalPrice': totalPrice,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  OfferModel copyWith({String? status}) => OfferModel(
    id: id,
    jobId: jobId,
    driverId: driverId,
    totalPrice: totalPrice,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
