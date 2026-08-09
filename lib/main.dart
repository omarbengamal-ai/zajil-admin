import 'package:flutter/material.dart';
import 'zajil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  Store.dailyReset();
  runApp(const ZajilApp());
}
