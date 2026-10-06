import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class DuplicateWarningModal extends StatelessWidget {
  final String existingReportSummary;
  final String? existingReportPhotoUrl; // null until Storage is wired up

  const DuplicateWarningModal({
    super.key,
    required this.existingReportSummary,
    this.existingReportPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.statusInjured.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.statusInjured,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Similar report found nearby',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Existing report photo placeholder
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accentPeach.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: existingReportPhotoUrl == null
                  ? const Icon(Icons.pets, color: AppColors.primary, size: 32)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(existingReportPhotoUrl!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 16),

            Text(
              existingReportSummary,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Is this the same animal?',
              style: AppTextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false), // "No, different"
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "No, it's different",
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true), // "Yes, same animal"
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Yes, same animal',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}