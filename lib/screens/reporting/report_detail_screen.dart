import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/status_pill.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  // TODO: replace with real data fetched from Firestore using widget.reportId
  final String petName = 'Milo — Golden Retriever';
  final String category = 'LOST';
  final bool reporterVerified = true;
  final String status = 'Active';
  final String distance = '0.4 km';
  final String lastSeen = '2h ago';
  final String sightingArea = 'Downtown Core · 500 m radius';
  final String reportedBy = 'Anjali P.';
  bool isResolved = false;
  bool isSaved = false;

  Future<void> _markAsResolved() async {
    // TODO once Firebase is connected:
    // Update Firestore 'reports/{reportId}' -> { status: 'Resolved' }
    setState(() => isResolved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as resolved (placeholder — Firebase pending)')),
    );
  }

  void _messageReporter() {
    // TODO: navigate to chat screen with a thread tied to this report's reporter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat (coming soon)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.textPrimary,
            ),
            onPressed: () => setState(() => isSaved = !isSaved),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.accentPeach.withOpacity(0.3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(Icons.pets, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Verified reporter badge
            if (reporterVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.statusFound.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified, size: 14, color: AppColors.statusFound),
                    SizedBox(width: 4),
                    Text(
                      'Verified reporter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusFound,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),

            // Pet name
            Text(petName, style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            StatusPill(label: isResolved ? 'RESOLVED' : category),
            const SizedBox(height: 20),

            // Info cards row: Status / Distance / Last Seen
            Row(
              children: [
                Expanded(child: _infoCard('STATUS', isResolved ? 'Resolved' : status)),
                const SizedBox(width: 10),
                Expanded(child: _infoCard('DISTANCE', distance)),
                const SizedBox(width: 10),
                Expanded(child: _infoCard('LAST SEEN', lastSeen)),
              ],
            ),
            const SizedBox(height: 24),

            // Sighting area / mini-map placeholder
            Text('Sighting area', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // TODO: replace with google_maps_flutter radius view
                  const Icon(Icons.map_outlined, size: 40, color: AppColors.textSecondary),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Text(sightingArea, style: AppTextStyles.caption),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Text(
                      'Directions',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reported by
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Reported by $reportedBy', style: AppTextStyles.bodyText),
                const SizedBox(width: 8),
                if (reporterVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusFound.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.statusFound,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _messageReporter,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Message reporter',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isResolved ? null : _markAsResolved,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isResolved ? 'Resolved' : 'Mark as resolved',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}