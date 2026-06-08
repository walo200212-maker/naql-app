class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String userTypeSelect = '/user-type';

  // Client
  static const String clientHome = '/client/home';
  static const String postJob = '/client/post-job';
  static const String jobPosted = '/client/job-posted';
  static const String driverOffers = '/client/offers';
  static const String driverProfile = '/client/driver-profile';
  static const String jobConfirmed = '/client/job-confirmed';
  static const String jobInProgress = '/client/job-in-progress';
  static const String jobComplete = '/client/job-complete';
  static const String clientHistory = '/client/history';
  static const String clientProfile = '/client/profile';

  // Driver
  static const String driverRegistration = '/driver/register';
  static const String driverHome = '/driver/home';
  static const String jobDetail = '/driver/job-detail';
  static const String driverActiveJob = '/driver/active-job';
  static const String wallet = '/driver/wallet';
  static const String topUp = '/driver/topup';
  static const String driverProfileScreen = '/driver/profile';
  static const String lowBalance = '/driver/low-balance';

  // Shared
  static const String settings = '/settings';
  static const String support = '/support';
  static const String notifications = '/notifications';
}
