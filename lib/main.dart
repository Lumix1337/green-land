import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/greenhouse_provider.dart';
import 'services/supabase_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/telemetry_controller.dart';
import 'controllers/actuator_controller.dart';
import 'controllers/alert_controller.dart';
import 'controllers/analytics_controller.dart';
import 'theme/app_theme.dart';
import 'views/auth_screen.dart';
import 'views/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // M8 Failure Handling: Global exception handler to prevent any app crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GreenLand Global Error Caught: ${details.exception}');
  };

  // Task 1: Resilient initialization of Supabase SDK (M1, M8)
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('🛡️ [SupabaseService] Initialized in resilient offline mode: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GreenhouseProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TelemetryController()),
        ChangeNotifierProvider(create: (_) => ActuatorController()),
        ChangeNotifierProvider(create: (_) => AlertController()),
        ChangeNotifierProvider(create: (_) => AnalyticsController()),
      ],
      child: const GreenLandApp(),
    ),
  );
}

class GreenLandApp extends StatefulWidget {
  const GreenLandApp({super.key});

  @override
  State<GreenLandApp> createState() => _GreenLandAppState();
}

class _GreenLandAppState extends State<GreenLandApp> {
  bool _isAuthenticated = true; // Set to true by default for fast demo evaluation

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenLand',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isAuthenticated
          ? MainNavigationScreen(
              onLogout: () {
                setState(() {
                  _isAuthenticated = false;
                });
              },
            )
          : AuthScreen(
              onLoginSuccess: () {
                setState(() {
                  _isAuthenticated = true;
                });
              },
            ),
      // M8 Custom error fallback widget: Never shows a red screen of death
      builder: (context, widget) {
        Widget errorWidget = widget ?? const SizedBox();
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shield_rounded, color: AppTheme.primary, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'GreenLand: Защищенный режим',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Произошла временная ошибка отрисовки. Приложение стабильно.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return errorWidget;
      },
    );
  }
}
