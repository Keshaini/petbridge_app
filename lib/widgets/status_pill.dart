import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String label;

  const StatusPill({super.key, required this.label});

  Color get _color {
    switch (label.toLowerCase()) {
      case 'lost':
        return AppColors.statusLost;
      case 'found':
        return AppColors.statusFound;
      case 'injured':
        return AppColors.statusInjured;
      case 'resolved':
        return AppColors.statusResolved;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}