
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../models/report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportModel? report;
  bool isLoading = true;
  bool isSaved = false;
  bool isUpdating = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final fetched = await FirestoreService.getReport(widget.reportId);

      if (!mounted) return;

      setState(() {
        report = fetched;
        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = 'Unable to load this report. Please try again.';
      });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my-reports');
    }
  }

  Future<void> _markAsResolved() async {
    if (report == null || isUpdating) return;

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
          petName: report!.petName,
          category: report!.category,
          animalType: report!.animalType,
          photoUrl: report!.photoUrl,
          location: report!.location,
          locationLabel: report!.locationLabel,
          locationRadius: report!.locationRadius,
          description: report!.description,
          status: 'Resolved',
          timestamp: report!.timestamp,
          claimedBy: report!.claimedBy,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as resolved.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update the report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  void _messageReporter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaging will be available soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  loadError!,
                  style: AppTextStyles.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      loadError = null;
                    });
                    _loadReport();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (report == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.find_in_page_outlined,
                  size: 52,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Report not found',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This report may have been removed or is no longer available.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _goBack,
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentReport = report!;
    final bool isResolved = currentReport.status.toLowerCase() == 'resolved';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Image header with floating navigation buttons.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SizedBox(
                        height: 280,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _buildReportImage(
                                currentReport.photoUrl,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: _roundIconButton(
                                icon: Icons.arrow_back,
                                onPressed: _goBack,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: _roundIconButton(
                                icon: isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                onPressed: () {
                                  setState(() => isSaved = !isSaved);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isSaved
                                            ? 'Report saved.'
                                            : 'Report removed from saved items.',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              left: 14,
                              bottom: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? Colors.green.shade700
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isResolved
                                          ? Icons.check_circle_outline
                                          : Icons.pets,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isResolved
                                          ? 'RESOLVED'
                                          : currentReport.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Report heading.
                        Text(
                          currentReport.petName.trim().isNotEmpty
                              ? currentReport.petName
                              : '${currentReport.animalType} report',
                          style: AppTextStyles.heading1.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Reported ${_timeAgo(currentReport.timestamp)}',
                                style: AppTextStyles.bodyText.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Summary cards.
                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                icon: Icons.category_outlined,
                                label: 'CATEGORY',
                                value: currentReport.category,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _infoCard(
                                icon: Icons.pets_outlined,
                                label: 'ANIMAL',
                                value: currentReport.animalType,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Description section.
                        _sectionHeading(
                          icon: Icons.notes_rounded,
                          title: 'About this report',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Text(
                            currentReport.description.trim().isEmpty
                                ? 'No additional description was provided.'
                                : currentReport.description,
                            style: AppTextStyles.bodyText.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Location section.
                        _sectionHeading(
                          icon: Icons.location_on_outlined,
                          title: 'Sighting location',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accentPeach.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentReport.locationLabel.trim().isNotEmpty
                                          ? currentReport.locationLabel
                                          : 'Location selected on map',
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Reported sighting area',
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Search radius: ${currentReport.locationRadius.toStringAsFixed(1)} km',
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Current status.
                        _sectionHeading(
                          icon: Icons.track_changes_outlined,
                          title: 'Report status',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isResolved
                                    ? Icons.check_circle
                                    : Icons.pending_actions,
                                color: isResolved
                                    ? Colors.green.shade700
                                    : AppColors.primary,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isResolved
                                          ? 'This report is resolved'
                                          : 'Awaiting resolution',
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isResolved
                                          ? 'The report has been marked as resolved.'
                                          : 'Update the status when the situation has been resolved.',
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // Persistent action area.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withOpacity(0.7),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _messageReporter,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                            color: AppColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: (isResolved || isUpdating)
                            ? null
                            : _markAsResolved,
                        icon: isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isResolved
                                    ? Icons.check_circle_outline
                                    : Icons.check_circle,
                              ),
                        label: Text(
                          isUpdating
                              ? 'Updating...'
                              : isResolved
                                  ? 'Resolved'
                                  : 'Mark resolved',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportImage(String photoUrl) {
    if (photoUrl.trim().isEmpty) {
      return _imageFallback();
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          color: AppColors.accentPeach.withOpacity(0.3),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.accentPeach.withOpacity(0.3),
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets,
        size: 56,
        color: AppColors.primary,
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.textPrimary,
        ),
        tooltip: icon == Icons.arrow_back ? 'Go back' : 'Save report',
      ),
    );
  }

  Widget _sectionHeading({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.trim().isEmpty ? 'Not specified' : value,
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.isNegative) {
      return 'just now';
    }

    if (diff.inMinutes < 1) {
      return 'just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }

    if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    }

    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}mo ago';
    }

    return '${(diff.inDays / 365).floor()}y ago';
  }
}