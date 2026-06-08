import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../models/offer_model.dart';
import '../models/driver_model.dart';
import '../models/transaction_model.dart';
import '../models/topup_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── JOBS ──────────────────────────────────────────────────────────────────

  Future<String> createJob(JobModel job) async {
    final ref = _db.collection(AppConstants.jobsCollection).doc();
    final newJob = JobModel(
      id: ref.id,
      clientId: job.clientId,
      pickupLocation: job.pickupLocation,
      dropoffLocation: job.dropoffLocation,
      distanceKm: job.distanceKm,
      itemsDescription: job.itemsDescription,
      itemsPhotos: job.itemsPhotos,
      status: AppConstants.jobStatusOpen,
      city: job.city,
      isIntercity: job.isIntercity,
      createdAt: DateTime.now(),
    );
    await ref.set(newJob.toMap());
    return ref.id;
  }

  Stream<List<JobModel>> watchClientJobs(String clientId) {
    return _db
        .collection(AppConstants.jobsCollection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<JobModel?> watchJob(String jobId) {
    return _db
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .snapshots()
        .map((d) => d.exists ? JobModel.fromMap(d.data()!, d.id) : null);
  }

  Stream<List<JobModel>> watchOpenJobsByCity(String city) {
    return _db
        .collection(AppConstants.jobsCollection)
        .where('status', isEqualTo: AppConstants.jobStatusOpen)
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _db
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .update({'status': status});
  }

  Future<void> matchJobWithDriver({
    required String jobId,
    required String driverId,
    required String offerId,
    required double agreedPrice,
  }) async {
    await _db.collection(AppConstants.jobsCollection).doc(jobId).update({
      'status': AppConstants.jobStatusMatched,
      'matchedDriverId': driverId,
      'matchedOfferId': offerId,
      'agreedPrice': agreedPrice,
    });
  }

  Future<void> completeJob({
    required String jobId,
    required String driverId,
    required double agreedPrice,
    required double rating,
    required String review,
  }) async {
    final WriteBatch batch = _db.batch();

    // Update job
    batch.update(_db.collection(AppConstants.jobsCollection).doc(jobId), {
      'status': AppConstants.jobStatusCompleted,
      'clientRating': rating,
      'clientReview': review,
    });

    // Get driver current wallet
    final driverDoc = await _db
        .collection(AppConstants.driversCollection)
        .doc(driverId)
        .get();
    final driver = DriverModel.fromMap(driverDoc.data()!, driverDoc.id);
    final commission = agreedPrice * AppConstants.commissionRate;
    final newBalance = driver.walletBalance - commission;

    // Deduct commission from driver wallet
    batch.update(
      _db.collection(AppConstants.driversCollection).doc(driverId),
      {
        'walletBalance': newBalance,
        'totalJobs': FieldValue.increment(1),
        'rating': ((driver.rating * driver.totalJobs) + rating) /
            (driver.totalJobs + 1),
      },
    );

    // Create transaction record
    final txRef = _db.collection(AppConstants.transactionsCollection).doc();
    final tx = TransactionModel(
      id: txRef.id,
      driverId: driverId,
      jobId: jobId,
      amount: commission,
      type: AppConstants.txCommission,
      balanceBefore: driver.walletBalance,
      balanceAfter: newBalance,
      createdAt: DateTime.now(),
    );
    batch.set(txRef, tx.toMap());

    await batch.commit();
  }

  Future<void> rateDriver(String jobId, double rating, String review) async {
    await _db.collection(AppConstants.jobsCollection).doc(jobId).update({
      'clientRating': rating,
      'clientReview': review,
    });
  }

  // ── OFFERS ────────────────────────────────────────────────────────────────

  Future<void> submitOffer(OfferModel offer) async {
    final ref = _db.collection(AppConstants.offersCollection).doc();
    await ref.set(OfferModel(
      id: ref.id,
      jobId: offer.jobId,
      driverId: offer.driverId,
      totalPrice: offer.totalPrice,
      status: AppConstants.offerStatusPending,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Stream<List<OfferModel>> watchJobOffers(String jobId) {
    return _db
        .collection(AppConstants.offersCollection)
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: AppConstants.offerStatusPending)
        .orderBy('totalPrice')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => OfferModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> acceptOffer(String offerId) async {
    await _db
        .collection(AppConstants.offersCollection)
        .doc(offerId)
        .update({'status': AppConstants.offerStatusAccepted});
  }

  Future<void> rejectOtherOffers(String jobId, String acceptedOfferId) async {
    final offers = await _db
        .collection(AppConstants.offersCollection)
        .where('jobId', isEqualTo: jobId)
        .where('status', isEqualTo: AppConstants.offerStatusPending)
        .get();
    final batch = _db.batch();
    for (final doc in offers.docs) {
      if (doc.id != acceptedOfferId) {
        batch.update(doc.reference,
            {'status': AppConstants.offerStatusRejected});
      }
    }
    await batch.commit();
  }

  Stream<List<OfferModel>> watchDriverOffers(String driverId) {
    return _db
        .collection(AppConstants.offersCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => OfferModel.fromMap(d.data(), d.id)).toList());
  }

  // ── DRIVERS ───────────────────────────────────────────────────────────────

  Future<void> createDriverProfile(DriverModel driver) async {
    await _db
        .collection(AppConstants.driversCollection)
        .doc(driver.id)
        .set(driver.toMap());
    await _db
        .collection(AppConstants.usersCollection)
        .doc(driver.id)
        .set({
      'name': driver.name,
      'phone': driver.phone,
      'type': 'driver',
      'city': driver.city,
      'createdAt': Timestamp.now(),
    });
  }

  Future<DriverModel?> getDriver(String driverId) async {
    final doc = await _db
        .collection(AppConstants.driversCollection)
        .doc(driverId)
        .get();
    if (!doc.exists) return null;
    return DriverModel.fromMap(doc.data()!, doc.id);
  }

  Stream<DriverModel?> watchDriver(String driverId) {
    return _db
        .collection(AppConstants.driversCollection)
        .doc(driverId)
        .snapshots()
        .map((d) =>
            d.exists ? DriverModel.fromMap(d.data()!, d.id) : null);
  }

  Future<DriverModel?> getDriverByPhone(String phone) async {
    final query = await _db
        .collection(AppConstants.driversCollection)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return DriverModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  // ── WALLET / TRANSACTIONS ─────────────────────────────────────────────────

  Stream<List<TransactionModel>> watchDriverTransactions(String driverId) {
    return _db
        .collection(AppConstants.transactionsCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TransactionModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── TOP-UPS ───────────────────────────────────────────────────────────────

  Future<void> submitTopUp(TopUpModel topup) async {
    final ref = _db.collection(AppConstants.topupsCollection).doc();
    await ref.set(TopUpModel(
      id: ref.id,
      driverId: topup.driverId,
      amount: topup.amount,
      reference: topup.reference,
      status: AppConstants.topupPending,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Stream<List<TopUpModel>> watchDriverTopUps(String driverId) {
    return _db
        .collection(AppConstants.topupsCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TopUpModel.fromMap(d.data(), d.id)).toList());
  }
}
