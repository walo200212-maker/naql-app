import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String type; // 'client' | 'driver'
  final String city;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.city,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? 'client',
      city: map['city'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'type': type,
    'city': city,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({String? name, String? city}) => UserModel(
    id: id,
    name: name ?? this.name,
    phone: phone,
    type: type,
    city: city ?? this.city,
    createdAt: createdAt,
  );
}
