class AppConstants {
  // Commission
  static const double commissionRate = 0.12;
  static const double minWalletBalance = 50.0;
  static const double lowWalletWarning = 100.0;

  // Cities
  static const List<String> supportedCities = ['Casablanca', 'Rabat'];
  static const String intercityCategory = 'Casablanca ↔ Rabat';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String driversCollection = 'drivers';
  static const String jobsCollection = 'jobs';
  static const String offersCollection = 'offers';
  static const String transactionsCollection = 'transactions';
  static const String topupsCollection = 'topups';

  // Storage paths
  static const String truckPhotosPath = 'truck_photos';
  static const String jobPhotosPath = 'job_photos';

  // Truck types
  static const List<String> truckTypes = ['Petit camion', 'Camion moyen', 'Grand camion'];

  // Job status
  static const String jobStatusOpen = 'open';
  static const String jobStatusMatched = 'matched';
  static const String jobStatusInProgress = 'inProgress';
  static const String jobStatusCompleted = 'completed';
  static const String jobStatusCancelled = 'cancelled';

  // Offer status
  static const String offerStatusPending = 'pending';
  static const String offerStatusAccepted = 'accepted';
  static const String offerStatusRejected = 'rejected';

  // Transaction types
  static const String txCommission = 'commission';
  static const String txTopup = 'topup';

  // TopUp status
  static const String topupPending = 'pending';
  static const String topupConfirmed = 'confirmed';

  // User types
  static const String userTypeClient = 'client';
  static const String userTypeDriver = 'driver';

  // Nearby radius (km)
  static const double nearbyJobRadiusKm = 25.0;

  // WhatsApp admin number (set your real number)
  static const String adminWhatsApp = '+212600000000';

  // Tawk.to
  static const String tawkPropertyId = 'YOUR_TAWK_PROPERTY_ID';
  static const String tawkWidgetId = 'YOUR_TAWK_WIDGET_ID';

  // Google Maps API key placeholder
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
}
