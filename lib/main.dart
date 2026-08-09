import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'zajil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  Store.dailyReset();
  T.dark = Store.settings()['dark'] == '1';
  runZonedGuarded(() {
    FlutterError.onError = (d) => debugPrint('ERR: ${d.exception}');
    runApp(const ZajilApp());
  }, (e, st) => debugPrint('ZONE ERR: $e')); // بيمنع البرنامج يقفل عند أي خطأ
}
