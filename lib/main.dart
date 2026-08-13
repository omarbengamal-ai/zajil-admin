import 'package:flutter/material.dart';
// تأكد من استدعاء ملف الشاشة الصحيح
// لو اسم الملف screens.dart تأكد من الاسم
import 'screens.dart'; 

void main() {
  runApp(const ZajilApp());
}

class ZajilApp extends StatelessWidget {
  const ZajilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zajil Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Cairo', // اختياري: لو عندك خط عربي
      ),
      // التأكد من أن الاتجاه من اليمين لليسار
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const LoginScreen(), // Start with login screen
    );
  }
}
