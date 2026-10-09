import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/status_pill.dart';
import '../../services/firestore_service.dart';
import '../../models/report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportModel? report;
  bool isLoading = true;
  bool isSaved = false;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final fetched = await FirestoreService.getReport(widget.reportId);

    if (!mounted) return;

    setState(() {
      report = fetched;
      isLoading = false;
    });
  }

  Future<void> _markAsResolved() async {
    if (report == null) return;

    setState(() => isUpdating = true);

    try {
      await FirestoreService.updateReport(
        widget.reportId,
        {'status': 'Resolved'},
      );

      if (!mounted) return;

      setState(() {
        report = ReportModel(
          reportId: report!.reportId,
          ownerUid: report!.ownerUid,
          category: report!.category,
          photoUrl: report!.photoUrl,
          location: report!.location,
          locationRadius: report!.locationRadius,
          description: report!.description,
          status: 'Resolved',
          timestamp: report!.timestamp,
          claimedBy: report!.claimedBy,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as resolved'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  void _messageReporter() {
    // TODO: navigate to chat screen with a thread tied to this report's reporter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat (coming soon)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (report == null) {
      return const Scaffold(
        body: Center(
          child: Text('Report not found'),
        ),
      );
    }

    final bool isResolved = report!.status == 'Resolved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() => isSaved = !isSaved);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.accentPeach.withOpacity(0.3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: report!.photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        report!.photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Center(
                            child: Icon(
                              Icons.pets,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.pets,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            Text(
              'Report',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),

            StatusPill(
              label: isResolved ? 'RESOLVED' : report!.category,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    'STATUS',
                    report!.status,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoCard(
                    'CATEGORY',
                    report!.category,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoCard(
                    'REPORTED',
                    _timeAgo(report!.timestamp),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Description',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 10),

            Text(
              report!.description.isEmpty
                  ? 'No description provided.'
                  : report!.description,
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 24),

            Text(
              'Sighting area',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Center(
                // TODO: replace with google_maps_flutter radius view
                child: Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _messageReporter,
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
                      'Message reporter',
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
                    onPressed: (isResolved || isUpdating)
                        ? null
                        : _markAsResolved,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isUpdating
                          ? 'Updating...'
                          : (isResolved
                              ? 'Resolved'
                              : 'Mark as resolved'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    return '${diff.inDays}d ago';
  }
}