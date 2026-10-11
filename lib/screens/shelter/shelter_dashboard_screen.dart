
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ShelterDashboardScreen extends StatefulWidget {
  const ShelterDashboardScreen({super.key});

  @override
  State<ShelterDashboardScreen> createState() =>
      _ShelterDashboardScreenState();
}

class _ShelterDashboardScreenState
    extends State<ShelterDashboardScreen> {
  bool urgentOnly = false;
  final Set<String> _claimingReports = {};

  static const Color background = Color(0xFFFFF9F1);
  static const Color primary = Color(0xFF8A624A);
  static const Color darkText = Color(0xFF34251D);
  static const Color mutedText = Color(0xFF8B8179);
  static const Color cardColor = Colors.white;
  static const Color urgentColor = Color(0xFFD9534F);
  static const Color greenColor = Color(0xFF4F8A65);

  bool _isUrgent(ReportModel report) {
    final category = report.category.toLowerCase();
    final description = report.description.toLowerCase();

    return category.contains('urgent') ||
        category.contains('emergency') ||
        category.contains('injur') ||
        description.contains('urgent') ||
        description.contains('emergency') ||
        description.contains('seriously injured');
  }

  String _reportTitle(ReportModel report) {
    if (report.petName.trim().isNotEmpty) {
      return report.petName.trim();
    }

    if (report.animalType.trim().isNotEmpty) {
      return report.animalType.trim();
    }

    if (report.category.trim().isNotEmpty) {
      return report.category.trim();
    }

    return 'Animal report';
  }

  String _timeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
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
    final uid = AuthService.currentUid;

    if (uid.isEmpty || uid == 'guest') {
      _showMessage('Please log in before claiming a report.');
      return;
    }

    if (_claimingReports.contains(report.reportId)) return;

    setState(() {
      _claimingReports.add(report.reportId);
    });

    try {
      await FirestoreService.claimReport(
        reportId: report.reportId,
        shelterUid: uid,
      );

      _showMessage('Report claimed successfully.');
    } catch (e) {
      _showMessage(
        'Unable to claim report: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _claimingReports.remove(report.reportId);
        });
      }
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 23),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetImage(ReportModel report) {
    if (report.photoUrl.trim().isNotEmpty) {
      return Image.network(
        report.photoUrl,
        width: double.infinity,
        height: 125,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder();
        },
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 125,
      width: double.infinity,
      color: const Color(0xFFF0E6DA),
      child: const Icon(
        Icons.pets,
        size: 48,
        color: primary,
      ),
    );
  }

  Widget _buildPetCard(ReportModel report) {
    final uid = AuthService.currentUid;
    final isUrgent = _isUrgent(report);
    final isClaimed = report.claimedBy.isNotEmpty;
    final claimedByMe = isClaimed && report.claimedBy == uid;
    final claimedByAnother = isClaimed && report.claimedBy != uid;
    final isClaiming = _claimingReports.contains(report.reportId);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            '/shelter-report-detail/${report.reportId}',
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUrgent
                  ? urgentColor.withAlpha(90)
                  : const Color(0xFFEDE3D8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildPetImage(report),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? urgentColor
                            : primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isUrgent
                            ? 'URGENT'
                            : report.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reportTitle(report),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report.locationLabel.isNotEmpty
                            ? report.locationLabel
                            : 'Location not provided',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _timeAgo(report.timestamp),
                        style: const TextStyle(
                          fontSize: 10,
                          color: mutedText,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isClaiming || claimedByAnother
                              ? null
                              : claimedByMe
                                  ? () {
                                      context.push(
                                        '/shelter-report-detail/${report.reportId}',
                                      );
                                    }
                                  : () => _claimReport(report),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: claimedByMe
                                ? greenColor
                                : primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFE5DED7),
                            disabledForegroundColor: mutedText,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isClaiming
                                ? 'Claiming...'
                                : claimedByMe
                                    ? 'View Claimed'
                                    : claimedByAnother
                                        ? 'Already Claimed'
                                        : 'Claim Report',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => context.go('/home'),
          ),
          _navItem(
            icon: Icons.map_outlined,
            label: 'Map',
            onTap: () => context.go('/map-search'),
          ),
          _navItem(
            icon: Icons.assignment_outlined,
            label: 'Dashboard',
            selected: true,
            onTap: () {},
          ),
          _navItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? primary : mutedText,
              size: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? primary : mutedText,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pets_outlined,
              size: 58,
              color: primary,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Shelter Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Help animals find safety and care.',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E5D8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: primary,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ReportModel>>(
                stream: FirestoreService.getActiveReports(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      'Could not load reports.\n'
                      'Check your internet connection and Firestore rules.\n\n'
                      '${snapshot.error}',
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primary,
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];
                  final urgentCount =
                      reports.where(_isUrgent).length;
                  final claimedCount = reports
                      .where((report) => report.claimedBy.isNotEmpty)
                      .length;

                  final displayedReports = urgentOnly
                      ? reports.where(_isUrgent).toList()
                      : reports;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            _buildStatCard(
                              icon: Icons.assignment_outlined,
                              label: 'Active Reports',
                              value: '${reports.length}',
                              iconColor: primary,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              icon: Icons.handshake_outlined,
                              label: 'Claimed',
                              value: '$claimedCount',
                              iconColor: greenColor,
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              icon: Icons.warning_amber_rounded,
                              label: 'Urgent',
                              value: '$urgentCount',
                              iconColor: urgentColor,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          12,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Reported Animals',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                            ),
                            const Text(
                              'Urgent only',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedText,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Switch.adaptive(
                              value: urgentOnly,
                              activeTrackColor: primary,
                              onChanged: (value) {
                                setState(() {
                                  urgentOnly = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: displayedReports.isEmpty
                            ? _buildEmptyState(
                                urgentOnly
                                    ? 'No urgent reports are currently available.'
                                    : 'No active reports have been submitted yet.',
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 290,
                                ),
                                itemCount: displayedReports.length,
                                itemBuilder: (context, index) {
                                  return _buildPetCard(
                                    displayedReports[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}
