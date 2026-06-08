import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/job_provider.dart';
import 'presentation/providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('fr', timeago.FrMessages());

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase reads from google-services.json (Android) / GoogleService-Info.plist (iOS).
  // Run `flutterfire configure` to auto-generate firebase_options.dart if preferred.
  await Firebase.initializeApp();

  await NotificationService().init();

  runApp(const NaqlApp());
}

class NaqlApp extends StatelessWidget {
  const NaqlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context.read<AuthProvider>());
          return MaterialApp.router(
            title: 'NaqlApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
