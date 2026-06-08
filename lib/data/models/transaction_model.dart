import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String driverId;
  final String? jobId;
  final double amount;
  final String type; // 'commission' | 'topup'
  final double balanceBefore;
  final double balanceAfter;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.driverId,
    this.jobId,
    required this.amount,
    required this.type,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
  });

  bool get isDebit => type == 'commission';

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      driverId: map['driverId'] ?? '',
      jobId: map['jobId'],
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? '',
      balanceBefore: (map['balanceBefore'] ?? 0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'jobId': jobId,
    'amount': amount,
    'type': type,
    'balanceBefore': balanceBefore,
    'balanceAfter': balanceAfter,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
