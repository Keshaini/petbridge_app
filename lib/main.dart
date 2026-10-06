import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/reporting/create_report_screen.dart';

void main() {
  runApp(const PetBridgeApp());
}

class PetBridgeApp extends StatelessWidget {
  const PetBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const CreateReportScreen(),
    );
  }
}