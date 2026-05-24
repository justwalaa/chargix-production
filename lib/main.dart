import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chargix_production/app.dart';
import 'package:chargix_production/core/app_settings_controller.dart';
import 'package:chargix_production/core/app_settings_scope.dart';
import 'package:chargix_production/screens/splash/splash_screen.dart';
import 'package:chargix_production/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp();

  runApp(const ChargixRoot());
}

/// Single root — [AppSettingsScope] wraps the entire app so Settings/Preferences
/// never lose scope when pushed from any navigator.
class ChargixRoot extends StatefulWidget {
  const ChargixRoot({super.key});

  @override
  State<ChargixRoot> createState() => _ChargixRootState();
}

class _ChargixRootState extends State<ChargixRoot> {
  final AppSettingsController _settings = AppSettingsController();
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    unawaited(_settings.load());
  }

  void _onSplashComplete() {
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      notifier: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          if (!_splashDone) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: SplashScreen(
                key: const ValueKey('splash'),
                onComplete: _onSplashComplete,
              ),
            );
          }
          return const ChargixApp();
        },
      ),
    );
  }
}
