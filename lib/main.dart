import 'package:flutter/material.dart';
import 'package:speleoloc/app.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/document_format_registry.dart';
import 'package:speleoloc/utils/app_start_counter.dart';
import 'package:speleoloc/utils/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register built-in document format handlers (editors & viewers).
  registerBuiltInDocumentFormats();

  // Track application start count.
  await AppStartCounter.increment();

  // Load localization strings from JSON assets.
  await LocServ.inst.load();

  // Load saved language preference before building the widget tree (#14, #25)
  try {
    final langRow = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals('app_language')))
        .getSingleOrNull();
    if (langRow != null && langRow.value != null) {
      await LocServ.inst.setLocale(langRow.value!);
    }
  } catch (_) {
    // DB not ready yet — use default locale
  }

  runApp(const SpeleoLocApp());
}