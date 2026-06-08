import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/job_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/storage_service.dart';
import '../../core/utils/distance_calculator.dart';
import '../../core/constants/app_constants.dart';

class JobProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  List<JobModel> _clientJobs = [];
  List<JobModel> _openJobs = [];
  List<OfferModel> _jobOffers = [];
  JobModel? _activeJob;
  bool _isLoading = false;
  String? _error;

  // Post job form state
  LocationData? _pickup;
  LocationData? _dropoff;
  double _distanceKm = 0;
  List<File> _selectedPhotos = [];
  String _description = '';
  String _city = AppConstants.supportedCities[0];

  List<JobModel> get clientJobs => _clientJobs;
  List<JobModel> get openJobs => _openJobs;
  List<OfferModel> get jobOffers => _jobOffers;
  JobModel? get activeJob => _activeJob;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LocationData? get pickup => _pickup;
  LocationData? get dropoff => _dropoff;
  double get distanceKm => _distanceKm;
  List<File> get selectedPhotos => _selectedPhotos;
  String get description => _description;
  String get city => _city;

  void setPickup(LocationData loc) {
    _pickup = loc;
    _recalcDistance();
    notifyListeners();
  }

  void setDropoff(LocationData loc) {
    _dropoff = loc;
    _recalcDistance();
    notifyListeners();
  }

  void setCity(String c) {
    _city = c;
    notifyListeners();
  }

  void setDescription(String d) {
    _description = d;
    notifyListeners();
  }

  void addPhoto(File file) {
    if (_selectedPhotos.length < 5) {
      _selectedPhotos.add(file);
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    _selectedPhotos.removeAt(index);
    notifyListeners();
  }

  void _recalcDistance() {
    if (_pickup != null && _dropoff != null) {
      _distanceKm = DistanceCalculator.calculateKm(
        LatLng(_pickup!.lat, _pickup!.lng),
        LatLng(_dropoff!.lat, _dropoff!.lng),
      );
    }
  }

  Future<String?> postJob(String clientId) async {
    if (_pickup == null || _dropoff == null) return null;
    _setLoading(true);
    try {
      // Upload photos first
      List<String> photoUrls = [];
      if (_selectedPhotos.isNotEmpty) {
        final tempJobId = DateTime.now().millisecondsSinceEpoch.toString();
        photoUrls = await _storage.uploadJobPhotos(tempJobId, _selectedPhotos);
      }

      final job = JobModel(
        id: '',
        clientId: clientId,
        pickupLocation: _pickup!,
        dropoffLocation: _dropoff!,
        distanceKm: _distanceKm,
        itemsDescription: _description,
        itemsPhotos: photoUrls,
        status: AppConstants.jobStatusOpen,
        city: _city,
        isIntercity: _city == AppConstants.intercityCategory,
        createdAt: DateTime.now(),
      );
      final jobId = await _firestore.createJob(job);
      _resetForm();
      _setLoading(false);
      return jobId;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  void watchClientJobs(String clientId) {
    _firestore.watchClientJobs(clientId).listen((jobs) {
      _clientJobs = jobs;
      notifyListeners();
    });
  }

  void watchOpenJobs(String city) {
    _firestore.watchOpenJobsByCity(city).listen((jobs) {
      _openJobs = jobs;
      notifyListeners();
    });
  }

  void watchJob(String jobId) {
    _firestore.watchJob(jobId).listen((job) {
      _activeJob = job;
      notifyListeners();
    });
  }

  void watchJobOffers(String jobId) {
    _firestore.watchJobOffers(jobId).listen((offers) {
      _jobOffers = offers;
      notifyListeners();
    });
  }

  Future<void> selectDriver({
    required String jobId,
    required String driverId,
    required String offerId,
    required double agreedPrice,
  }) async {
    _setLoading(true);
    await _firestore.matchJobWithDriver(
      jobId: jobId,
      driverId: driverId,
      offerId: offerId,
      agreedPrice: agreedPrice,
    );
    await _firestore.acceptOffer(offerId);
    await _firestore.rejectOtherOffers(jobId, offerId);
    _setLoading(false);
  }

  Future<void> confirmJobStarted(String jobId) async {
    await _firestore.updateJobStatus(jobId, AppConstants.jobStatusInProgress);
  }

  Future<void> completeJob({
    required String jobId,
    required String driverId,
    required double agreedPrice,
    required double rating,
    required String review,
  }) async {
    _setLoading(true);
    await _firestore.completeJob(
      jobId: jobId,
      driverId: driverId,
      agreedPrice: agreedPrice,
      rating: rating,
      review: review,
    );
    _setLoading(false);
  }

  void _resetForm() {
    _pickup = null;
    _dropoff = null;
    _distanceKm = 0;
    _selectedPhotos = [];
    _description = '';
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
