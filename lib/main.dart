import 'package:flutter/material.dart';
import 'screens/intro_screen.dart';
import 'screens/phone_input_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/company_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/intro',
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/phone': (context) => const PhoneInputScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/company': (context) => const CompanySelectionScreen(),
      },
    );
  }
}
