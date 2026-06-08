import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String truckType;
  final String truckPhotoUrl;
  final double pricePerKm;
  final double rating;
  final int totalJobs;
  final double walletBalance;
  final bool isActive;
  final bool isBlocked;
  final String city;
  final GeoPoint? location;
  final DateTime createdAt;
  final bool isApproved;
  final bool isOnline;

  // Document fields (from registration wizard)
  final String cinNumber;
  final String cinFrontUrl;
  final String cinBackUrl;
  final String driverLicenseUrl;
  final String selfieUrl;
  final String truckRegistrationFrontUrl;
  final String truckRegistrationBackUrl;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.truckType,
    required this.truckPhotoUrl,
    required this.pricePerKm,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.walletBalance = 0.0,
    this.isActive = false,
    this.isBlocked = false,
    required this.city,
    this.location,
    required this.createdAt,
    this.isApproved = false,
    this.isOnline = false,
    this.cinNumber = '',
    this.cinFrontUrl = '',
    this.cinBackUrl = '',
    this.driverLicenseUrl = '',
    this.selfieUrl = '',
    this.truckRegistrationFrontUrl = '',
    this.truckRegistrationBackUrl = '',
  });

  bool get canAcceptJobs => !isBlocked && walletBalance >= 50.0 && isApproved;

  factory DriverModel.fromMap(Map<String, dynamic> map, String id) {
    return DriverModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      truckType: map['truckType'] ?? '',
      truckPhotoUrl: map['truckPhotoUrl'] ?? '',
      pricePerKm: (map['pricePerKm'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      totalJobs: map['totalJobs'] ?? 0,
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      city: map['city'] ?? '',
      location: map['location'] as GeoPoint?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isApproved: map['isApproved'] ?? false,
      isOnline: map['isOnline'] ?? false,
      cinNumber: map['cinNumber'] ?? '',
      cinFrontUrl: map['cinFrontUrl'] ?? '',
      cinBackUrl: map['cinBackUrl'] ?? '',
      driverLicenseUrl: map['driverLicenseUrl'] ?? '',
      selfieUrl: map['selfieUrl'] ?? '',
      truckRegistrationFrontUrl: map['truckRegistrationFrontUrl'] ?? '',
      truckRegistrationBackUrl: map['truckRegistrationBackUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'truckType': truckType,
    'truckPhotoUrl': truckPhotoUrl,
    'pricePerKm': pricePerKm,
    'rating': rating,
    'totalJobs': totalJobs,
    'walletBalance': walletBalance,
    'isActive': isActive,
    'isBlocked': isBlocked,
    'city': city,
    'location': location,
    'createdAt': Timestamp.fromDate(createdAt),
    'isApproved': isApproved,
    'isOnline': isOnline,
    'cinNumber': cinNumber,
    'cinFrontUrl': cinFrontUrl,
    'cinBackUrl': cinBackUrl,
    'driverLicenseUrl': driverLicenseUrl,
    'selfieUrl': selfieUrl,
    'truckRegistrationFrontUrl': truckRegistrationFrontUrl,
    'truckRegistrationBackUrl': truckRegistrationBackUrl,
  };

  DriverModel copyWith({
    double? walletBalance,
    double? rating,
    int? totalJobs,
    bool? isActive,
    bool? isBlocked,
    bool? isApproved,
    bool? isOnline,
    GeoPoint? location,
  }) {
    return DriverModel(
      id: id,
      name: name,
      phone: phone,
      truckType: truckType,
      truckPhotoUrl: truckPhotoUrl,
      pricePerKm: pricePerKm,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      walletBalance: walletBalance ?? this.walletBalance,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      city: city,
      location: location ?? this.location,
      createdAt: createdAt,
      isApproved: isApproved ?? this.isApproved,
      isOnline: isOnline ?? this.isOnline,
      cinNumber: cinNumber,
      cinFrontUrl: cinFrontUrl,
      cinBackUrl: cinBackUrl,
      driverLicenseUrl: driverLicenseUrl,
      selfieUrl: selfieUrl,
      truckRegistrationFrontUrl: truckRegistrationFrontUrl,
      truckRegistrationBackUrl: truckRegistrationBackUrl,
    );
  }
}
