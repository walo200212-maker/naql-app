import 'package:cloud_firestore/cloud_firestore.dart';

class TopUpModel {
  final String id;
  final String driverId;
  final double amount;
  final String reference; // CashPlus / Wafacash ref
  final String status; // 'pending' | 'confirmed'
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const TopUpModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.reference,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });

  factory TopUpModel.fromMap(Map<String, dynamic> map, String id) {
    return TopUpModel(
      id: id,
      driverId: map['driverId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reference: map['reference'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'amount': amount,
    'reference': reference,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
  };
}
