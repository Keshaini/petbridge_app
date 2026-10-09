
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class DuplicateWarningModal extends StatelessWidget {
  final String existingReportSummary;
  final String? existingReportPhotoUrl;

  const DuplicateWarningModal({
    super.key,
    required this.existingReportSummary,
    this.existingReportPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
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

            // Photo of the existing potentially duplicate report
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 110,
                height: 110,
                child: _buildReportPhoto(),
              ),
            ),

            const SizedBox(height: 16),

            // Information about the existing report
            Text(
              existingReportSummary,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Is this the same animal?',
              style: AppTextStyles.bodyText,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // User choices
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "No, it's different",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Yes, same animal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildReportPhoto() {
    final photoUrl = existingReportPhotoUrl;

    // Show a fallback if the existing report has no photo.
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return _buildPhotoFallback();
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      width: 110,
      height: 110,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: AppColors.accentPeach.withOpacity(0.3),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPhotoFallback();
      },
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      color: AppColors.accentPeach.withOpacity(0.3),
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }
}