import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/user_model.dart';
import '../../data/models/driver_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../core/constants/app_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  DriverModel? _driver;
  String? _verificationId;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _locationSub;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDriver => _user?.type == AppConstants.userTypeDriver;
  bool get isClient => _user?.type == AppConstants.userTypeClient;
  String? get uid => _authService.currentUser?.uid;

  void init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _stopLocationStream();
        _status = AuthStatus.unauthenticated;
        _user = null;
        _driver = null;
      } else {
        final profile = await _authService.getUserProfile(firebaseUser.uid);
        if (profile != null) {
          _user = profile;
          if (profile.type == AppConstants.userTypeDriver) {
            _driver = await _firestoreService.getDriver(firebaseUser.uid);
          }
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
      notifyListeners();
    });
  }

  Future<void> sendOtp(String phoneNumber) async {
    _setLoading(true);
    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (id) {
        _verificationId = id;
        _setLoading(false);
      },
      onError: (e) {
        _error = e;
        _setLoading(false);
      },
    );
  }

  Future<bool> verifyOtp(String code) async {
    if (_verificationId == null) return false;
    _setLoading(true);
    try {
      final cred = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (cred?.user == null) {
        _error = 'Code incorrect';
        _setLoading(false);
        return false;
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    }
  }

  Future<void> createClientProfile({
    required String name,
    required String city,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    _setLoading(true);
    await _authService.createClientProfile(
      uid: uid,
      name: name,
      phone: _authService.currentUser!.phoneNumber ?? '',
      city: city,
    );
    _user = await _authService.getUserProfile(uid);
    _status = AuthStatus.authenticated;
    _setLoading(false);
    notifyListeners();
  }

  Future<void> createDriverProfile(DriverModel driver) async {
    _setLoading(true);
    await _firestoreService.createDriverProfile(driver);
    _driver = driver;
    _user = UserModel(
      id: driver.id,
      name: driver.name,
      phone: driver.phone,
      type: AppConstants.userTypeDriver,
      city: driver.city,
      createdAt: driver.createdAt,
    );
    _status = AuthStatus.authenticated;
    _setLoading(false);
    notifyListeners();
  }

  Future<void> loadCurrentUserProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final profile = await _authService.getUserProfile(uid);
    if (profile != null) {
      _user = profile;
      if (profile.type == AppConstants.userTypeDriver) {
        _driver = await _firestoreService.getDriver(uid);
      }
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> refreshDriver() async {
    if (uid == null) return;
    _driver = await _firestoreService.getDriver(uid!);
    notifyListeners();
  }

  /// Toggles driver online/offline status.
  /// Going online starts live location streaming to Firestore.
  Future<void> toggleOnline(bool online) async {
    final id = uid;
    if (_driver == null || id == null) return;

    if (online) {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
    }

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(id)
        .update({'isOnline': online});

    _driver = _driver!.copyWith(isOnline: online);

    if (online) {
      _startLocationStream(id);
    } else {
      _stopLocationStream();
    }

    notifyListeners();
  }

  void _startLocationStream(String driverId) {
    _locationSub?.cancel();
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen((pos) {
      FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
        'location': GeoPoint(pos.latitude, pos.longitude),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    });
  }

  void _stopLocationStream() {
    _locationSub?.cancel();
    _locationSub = null;
  }

  Future<void> signOut() async {
    final id = uid;
    if (_driver != null && id != null) {
      _stopLocationStream();
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(id)
          .update({'isOnline': false});
    }
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    _driver = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLocationStream();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
