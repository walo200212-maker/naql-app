import 'package:cloud_firestore/cloud_firestore.dart';

class LocationData {
  final String address;
  final double lat;
  final double lng;

  const LocationData({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
    address: map['address'] ?? '',
    lat: (map['lat'] ?? 0).toDouble(),
    lng: (map['lng'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {'address': address, 'lat': lat, 'lng': lng};
}

class JobModel {
  final String id;
  final String clientId;
  final LocationData pickupLocation;
  final LocationData dropoffLocation;
  final double distanceKm;
  final String itemsDescription;
  final List<String> itemsPhotos;
  final String status;
  final String city;
  final bool isIntercity;
  final DateTime createdAt;
  final String? matchedDriverId;
  final String? matchedOfferId;
  final double? agreedPrice;
  final double? clientRating;
  final String? clientReview;

  const JobModel({
    required this.id,
    required this.clientId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distanceKm,
    required this.itemsDescription,
    this.itemsPhotos = const [],
    required this.status,
    required this.city,
    this.isIntercity = false,
    required this.createdAt,
    this.matchedDriverId,
    this.matchedOfferId,
    this.agreedPrice,
    this.clientRating,
    this.clientReview,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      clientId: map['clientId'] ?? '',
      pickupLocation: LocationData.fromMap(map['pickupLocation'] ?? {}),
      dropoffLocation: LocationData.fromMap(map['dropoffLocation'] ?? {}),
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      itemsDescription: map['itemsDescription'] ?? '',
      itemsPhotos: List<String>.from(map['itemsPhotos'] ?? []),
      status: map['status'] ?? 'open',
      city: map['city'] ?? '',
      isIntercity: map['isIntercity'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      matchedDriverId: map['matchedDriverId'],
      matchedOfferId: map['matchedOfferId'],
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble(),
      clientRating: (map['clientRating'] as num?)?.toDouble(),
      clientReview: map['clientReview'],
    );
  }

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'pickupLocation': pickupLocation.toMap(),
    'dropoffLocation': dropoffLocation.toMap(),
    'distanceKm': distanceKm,
    'itemsDescription': itemsDescription,
    'itemsPhotos': itemsPhotos,
    'status': status,
    'city': city,
    'isIntercity': isIntercity,
    'createdAt': Timestamp.fromDate(createdAt),
    'matchedDriverId': matchedDriverId,
    'matchedOfferId': matchedOfferId,
    'agreedPrice': agreedPrice,
    'clientRating': clientRating,
    'clientReview': clientReview,
  };

  JobModel copyWith({
    String? status,
    String? matchedDriverId,
    String? matchedOfferId,
    double? agreedPrice,
    double? clientRating,
    String? clientReview,
  }) {
    return JobModel(
      id: id,
      clientId: clientId,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      distanceKm: distanceKm,
      itemsDescription: itemsDescription,
      itemsPhotos: itemsPhotos,
      status: status ?? this.status,
      city: city,
      isIntercity: isIntercity,
      createdAt: createdAt,
      matchedDriverId: matchedDriverId ?? this.matchedDriverId,
      matchedOfferId: matchedOfferId ?? this.matchedOfferId,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      clientRating: clientRating ?? this.clientRating,
      clientReview: clientReview ?? this.clientReview,
    );
  }
}
