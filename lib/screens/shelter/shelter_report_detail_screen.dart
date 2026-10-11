import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SightingReportDetailScreen extends StatefulWidget {
  final String reportId;

  const SightingReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<SightingReportDetailScreen> createState() =>
      _SightingReportDetailScreenState();
}

class _SightingReportDetailScreenState
    extends State<SightingReportDetailScreen> {
  static const Color background = Color(0xFFFFF9F1);
  static const Color primary = Color(0xFF8A624A);
  static const Color darkText = Color(0xFF34251D);
  static const Color mutedText = Color(0xFF8B8179);
  static const Color greenColor = Color(0xFF4F8A65);
  static const Color redColor = Color(0xFFD9534F);

  bool isBookmarked = false;
  bool isProcessing = false;

  String _timeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _claimReport(ReportModel report) async {
    if (AuthService.currentUid == 'guest') {
      _showMessage('Please log in before claiming a report.');
      return;
    }

    setState(() => isProcessing = true);

    try {
      await FirestoreService.claimReport(
        reportId: report.reportId,
        shelterUid: AuthService.currentUid,
      );

      _showMessage('Report claimed successfully.');
    } catch (e) {
      _showMessage(
        'Unable to claim report: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _releaseClaim(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Release this report?'),
        content: const Text(
          'Other shelters will be able to claim this report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => isProcessing = true);

    try {
      await FirestoreService.releaseClaim(
        reportId: report.reportId,
        shelterUid: AuthService.currentUid,
      );

      _showMessage('Report claim released.');
    } catch (e) {
      _showMessage(
        'Unable to release claim: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _resolveReport(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve this report?'),
        content: const Text(
          'Only mark this report as resolved when the case has been handled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark resolved'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => isProcessing = true);

    try {
      await FirestoreService.resolveReport(
        reportId: report.reportId,
        shelterUid: AuthService.currentUid,
      );

      _showMessage('Report marked as resolved.');
    } catch (e) {
      _showMessage(
        'Unable to resolve report: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Widget _buildPhoto(ReportModel report) {
    if (report.photoUrl.trim().isNotEmpty) {
      return Image.network(
        report.photoUrl,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _photoPlaceholder();
        },
      );
    }

    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: const Color(0xFFF0E6DA),
      child: const Icon(
        Icons.pets,
        size: 75,
        color: primary,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(ReportModel report) {
    final uid = AuthService.currentUid;
    final isClaimed = report.claimedBy.isNotEmpty;
    final claimedByMe = isClaimed && report.claimedBy == uid;
    final claimedByAnother = isClaimed && report.claimedBy != uid;
    final isActive = report.status.toLowerCase() == 'active';
    final isResolved = !isActive;

    return Column(
      children: [
        Stack(
          children: [
            _buildPhoto(report),
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isResolved ? greenColor : redColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  tooltip: 'Bookmark report',
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: primary,
                  ),
                  onPressed: () {
                    setState(() {
                      isBookmarked = !isBookmarked;
                    });
                    _showMessage(
                      isBookmarked
                          ? 'Bookmarked for this session.'
                          : 'Bookmark removed.',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(
                report.petName.trim().isNotEmpty
                    ? report.petName
                    : report.animalType.trim().isNotEmpty
                        ? report.animalType
                        : 'Animal report',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                [
                  if (report.animalType.isNotEmpty) report.animalType,
                  if (report.category.isNotEmpty) report.category,
                ].join(' • '),
                style: const TextStyle(
                  fontSize: 13,
                  color: mutedText,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report status',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.status,
                            style: TextStyle(
                              color: isResolved ? greenColor : primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reported',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _timeAgo(report.timestamp),
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Report information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.location_on_outlined,
                title: 'Reported location',
                value: report.locationLabel.isNotEmpty
                    ? report.locationLabel
                    : 'Location label not provided',
              ),
              _infoRow(
                icon: Icons.radar,
                title: 'Location radius',
                value: '${report.locationRadius} km',
              ),
              _infoRow(
                icon: Icons.access_time,
                title: 'Report submitted',
                value: report.timestamp.toLocal().toString().split('.').first,
              ),
              const SizedBox(height: 12),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.description.isNotEmpty
                    ? report.description
                    : 'No additional description was provided.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: mutedText,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Shelter actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),
              if (claimedByAnother && isActive)
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This report has already been claimed by another shelter.',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (!isClaimed && isActive)
                _actionButton(
                  label: 'Claim report',
                  icon: Icons.handshake_outlined,
                  onPressed: isProcessing
                      ? null
                      : () => _claimReport(report),
                ),
              if (claimedByMe && isActive) ...[
                _actionButton(
                  label: 'Mark as resolved',
                  icon: Icons.check_circle_outline,
                  backgroundColor: greenColor,
                  onPressed: isProcessing
                      ? null
                      : () => _resolveReport(report),
                ),
                const SizedBox(height: 10),
                _actionButton(
                  label: 'Release claim',
                  icon: Icons.undo,
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  onPressed: isProcessing
                      ? null
                      : () => _releaseClaim(report),
                ),
              ],
              if (isResolved)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: greenColor,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This report has been resolved.',
                          style: TextStyle(
                            color: greenColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isProcessing) ...[
                const SizedBox(height: 14),
                const Center(
                  child: CircularProgressIndicator(color: primary),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.push('/map-search'),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Get directions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color backgroundColor = primary,
    Color foregroundColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: backgroundColor == Colors.white
                ? const BorderSide(color: primary)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkText,
        elevation: 0,
        title: const Text(
          'Report Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/shelter-dashboard');
            }
          },
        ),
      ),
      body: StreamBuilder<ReportModel?>(
        stream: FirestoreService.watchReport(widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this report.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: mutedText),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          final report = snapshot.data;

          if (report == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This report could not be found or has been deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedText),
                ),
              ),
            );
          }

          return _buildReport(report);
        },
      ),
    );
  }
}