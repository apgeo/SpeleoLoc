import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:speleoloc/screens/startup/startup_failure_page.dart';
import 'package:speleoloc/services/startup/startup_recovery.dart';
import 'package:speleoloc/utils/constants.dart';

/// The whole app when start-up failed: nothing of the normal app is built,
/// since its providers and screens need the database that may be what
/// failed.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    super.key,
    required this.error,
    required this.onRetry,
    required this.recovery,
  });

  final Object error;
  final Future<void> Function() onRetry;
  final StartupRecovery recovery;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ro')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: StartupFailurePage(
        error: error,
        onRetry: onRetry,
        recovery: recovery,
      ),
    );
  }
}
