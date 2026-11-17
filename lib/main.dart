import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

Future<({String url, String key})> _loadSupabaseConfig() async {
  var url = const String.fromEnvironment('SUPABASE_URL');
  var key = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (key.isEmpty) {
    key = const String.fromEnvironment('SUPABASE_ANON_KEY');
  }
  if (url.isNotEmpty && key.isNotEmpty) {
    return (url: url, key: key);
  }
  try {
    final raw = await rootBundle.loadString('assets/config/supabase.env');
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final k = trimmed.substring(0, eq).trim();
      final v = trimmed.substring(eq + 1).trim();
      if (k == 'SUPABASE_URL' && url.isEmpty) url = v;
      if ((k == 'SUPABASE_PUBLISHABLE_KEY' || k == 'SUPABASE_ANON_KEY') &&
          key.isEmpty) {
        key = v;
      }
    }
  } catch (_) {
    // No local supabase.env asset bundled; resilient mock mode remains active.
  }
  return (url: url, key: key);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // M8 Failure Handling: Global exception handler to prevent any app crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GreenLand Global Error Caught: ${details.exception}');
  };

  // Task 1: Resilient initialization of Supabase SDK (M1, M8)
  try {
    final config = await _loadSupabaseConfig();
    await SupabaseService().initialize(
      url: config.url,
      anonKey: config.key,
    );
  } catch (e) {
    debugPrint(
        '🛡️ [SupabaseService] Initialized in resilient offline mode: $e');
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
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    final session = SupabaseService().client?.auth.currentSession;
    if (session != null) {
      _isAuthenticated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context
              .read<GreenhouseProvider>()
              .setSignedInAccount(session.user.email ?? '');
        }
      });
    }
  }

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
                    Icon(Icons.shield_rounded,
                        color: AppTheme.primary, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'GreenLand: Safe mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The screen could not be displayed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
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
