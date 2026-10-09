import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/report_model.dart';
import '../../widgets/status_pill.dart';

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final title = report.petName.isNotEmpty
        ? report.petName
        : '${report.category} pet report';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Report Details',
          style: AppTextStyles.heading2,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: report.photoUrl.isNotEmpty
                  ? Image.network(
                      report.photoUrl,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _detailsPhotoPlaceholder();
                      },
                    )
                  : _detailsPhotoPlaceholder(),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: AppTextStyles.heading1,
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: report.category.toUpperCase(),
                ),
                StatusPill(
                  label: report.status.toUpperCase(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _detailSection(
              'Animal Type',
              report.animalType.isNotEmpty
                  ? report.animalType
                  : 'Not specified',
            ),

            _detailSection(
              'Description',
              report.description.isNotEmpty
                  ? report.description
                  : 'No description provided.',
            ),

            _detailSection(
              'Location',
              report.locationLabel.isNotEmpty
                  ? report.locationLabel
                  : 'Location not provided',
            ),

            _detailSection(
              'Coordinates',
              '${report.location.latitude.toStringAsFixed(6)}, '
                  '${report.location.longitude.toStringAsFixed(6)}',
            ),

            _detailSection(
              'Date Submitted',
              _formatReportDate(report.timestamp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String heading, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyText,
          ),
        ],
      ),
    );
  }

  Widget _detailsPhotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      color: AppColors.accentPeach,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }

  String _formatReportDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}