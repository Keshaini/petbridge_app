import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/report_model.dart';
import '../../services/auth_service.dart';

/// ============================================================================
/// USER PROFILE OVERVIEW SCREEN
/// File: lib/screens/shelter/profile_screen.dart
/// All figures come from Firestore: users/{uid} and the reports collection.
/// ============================================================================

class UserProfileOverviewScreen extends StatefulWidget {
  const UserProfileOverviewScreen({super.key});

  @override
  State<UserProfileOverviewScreen> createState() =>
      _UserProfileOverviewScreenState();
}

class _UserProfileOverviewScreenState
    extends State<UserProfileOverviewScreen> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late final Stream<List<ReportModel>> _ownStream;
  late final Stream<List<ReportModel>> _claimedStream;

  @override
  void initState() {
    super.initState();

    final uid = AuthService.currentUid;
    final db = FirebaseFirestore.instance;

    _userStream = db.collection('users').doc(uid).snapshots();

    // Reports this user created.
    _ownStream = db
        .collection('reports')
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map(_toReports);

    // Reports this user (as a shelter or vet) claimed.
    _claimedStream = db
        .collection('reports')
        .where('claimedBy', isEqualTo: uid)
        .snapshots()
        .map(_toReports);
  }

  static List<ReportModel> _toReports(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _userTypeLabel(String? type) {
    switch (type) {
      case 'finder':
        return 'Finder / community member';
      case 'shelter':
        return 'Shelter / rescue organisation';
      case 'vet':
        return 'Veterinary clinic';
      default:
        return 'Pet owner';
    }
  }

  String _memberSince(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      return 'Member since ${_months[date.month - 1]} ${date.year}';
    }
    return 'New member';
  }

  String _shortDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}';

  bool _isResolved(ReportModel r) => r.status.toLowerCase() == 'resolved';

  bool _isActive(ReportModel r) => r.status.toLowerCase() == 'active';

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),

                  // Everything below depends on live data.
                  _buildLiveSection(context),

                  const SizedBox(height: 20),
                  _buildLogout(context),
                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      '♡ PetBridge Rescue Network\n'
                      'Every rescue builds a kinder neighborhood.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E8E84),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildPersistentBottomNav(
                activeIndex: 3,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go('/home');
                      break;
                    case 1:
                      context.go('/map-search');
                      break;
                    case 2:
                      context.go('/my-reports');
                      break;
                    case 3:
                      context.go('/profile');
                      break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFCEFE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF2C2420),
            ),
          ),
        ),
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C2420),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/edit-profile'),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFCEFE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Color(0xFF6F3F24),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LIVE DATA: user document + own reports + claimed reports
  // ---------------------------------------------------------------------------

  Widget _buildLiveSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, userSnap) {
        final user = userSnap.data?.data();

        return StreamBuilder<List<ReportModel>>(
          stream: _ownStream,
          builder: (context, ownSnap) {
            final own = ownSnap.data ?? <ReportModel>[];

            return StreamBuilder<List<ReportModel>>(
              stream: _claimedStream,
              builder: (context, claimedSnap) {
                final claimed = claimedSnap.data ?? <ReportModel>[];

                return _buildProfileContent(context, user, own, claimed);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    Map<String, dynamic>? user,
    List<ReportModel> own,
    List<ReportModel> claimed,
  ) {
    // ---- Figures --------------------------------------------------------
    final Map<String, ReportModel> merged = {
      for (final r in own) r.reportId: r,
      for (final r in claimed) r.reportId: r,
    };

    final resolved = merged.values.where(_isResolved).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final int reportsMade = own.length;
    final int activeCount = own.where(_isActive).length;
    final int helped = resolved.length;
    final int trust = (user?['trustScore'] as num?)?.round() ?? 0;

    final int level = 1 + helped ~/ 5;
    final int intoLevel = helped % 5;
    final int toNext = 5 - intoLevel;

    // ---- Identity -------------------------------------------------------
    final String name = (user?['name'] as String?)?.trim() ?? '';
    final String photoUrl = (user?['photoUrl'] as String?)?.trim() ?? '';
    final String location = (user?['location'] as String?)?.trim() ?? '';
    final String typeLabel = _userTypeLabel(user?['userType'] as String?);

    final String subtitle = [
      _memberSince(user?['createdAt']),
      if (location.isNotEmpty) location,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Photo, name, account type -----------------------------------
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _defaultProfileImage(),
                            )
                          : _defaultProfileImage(),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: () => context.push('/edit-profile'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6F3F24),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name.isEmpty ? 'PetBridge user' : name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2420),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE1CC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A311A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF8A7D75),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ---- Level banner (worked out from resolved cases) ---------------
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDBB84),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.military_tech_outlined,
                      color: Color(0xFF9E643E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Neighborhood Hero · Lvl $level',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: Color(0xFF2C2420),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$toNext more resolved ${toNext == 1 ? 'case' : 'cases'} '
                          'to reach Level ${level + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4C3E36),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$intoLevel/5',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF2C2420),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: intoLevel / 5,
                  backgroundColor: const Color(0x80FFFFFF),
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xFF5A311A),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---- Metrics -------------------------------------------------------
        Row(
          children: [
            _buildMetricTile(
              Icons.assignment_outlined,
              '$reportsMade',
              'Reports Made',
            ),
            const SizedBox(width: 10),
            _buildMetricTile(
              Icons.volunteer_activism_outlined,
              '$helped',
              'Cases Resolved',
            ),
            const SizedBox(width: 10),
            _buildMetricTile(
              Icons.verified_user_outlined,
              '$trust',
              'Trust Score',
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ---- Recent rescues -----------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Rescues',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C2420),
              ),
            ),
            InkWell(
              onTap: () => context.go('/my-reports'),
              child: Text(
                'See all ($helped)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBA5D43),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (resolved.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.pets_outlined, color: Color(0xFF8A5332)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No resolved cases yet. Cases you resolve will '
                    'appear here.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8A7D75),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(child: _buildRescueCard(resolved[0])),
              const SizedBox(width: 12),
              Expanded(
                child: resolved.length > 1
                    ? _buildRescueCard(resolved[1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // ---- Account & preferences ------------------------------------------
        const Text(
          'ACCOUNT & PREFERENCES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Color(0xFF8A7D75),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              _buildSettingsRow(
                icon: Icons.description_outlined,
                title: 'My Reports',
                badge: '$activeCount active',
                badgeBg: const Color(0xFFFDD5B7),
                onTap: () => context.go('/my-reports'),
              ),
              _settingsDivider(),
              _buildSettingsRow(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                onTap: () => context.push('/edit-profile'),
              ),
              _settingsDivider(),
              _buildSettingsRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
              _settingsDivider(),
              _buildSettingsRow(
                icon: Icons.settings_outlined,
                title: 'Settings & Language',
                subtitle: 'English (US)',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Widget _buildLogout(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        try {
          await AuthService.signOut();

          if (context.mounted) {
            context.go('/login');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to log out. Please try again.'),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDDD9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 16,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD32F2F),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Color(0xFFD32F2F),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SMALL WIDGETS
  // ---------------------------------------------------------------------------

  static Widget _defaultProfileImage() {
    return Container(
      width: 92,
      height: 92,
      color: const Color(0xFFFCEFE7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 48,
        color: Color(0xFF9E8E84),
      ),
    );
  }

  static Widget _settingsDivider() {
    return const Divider(height: 1, indent: 56, color: Color(0xFFF3ECE6));
  }

  static Widget _buildMetricTile(IconData icon, String value, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8A5332)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C2420),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF8A7D75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescueCard(ReportModel report) {
    final String title = report.petName.trim().isNotEmpty
        ? report.petName
        : (report.animalType.trim().isNotEmpty
            ? '${report.animalType} report'
            : 'Pet report');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFCEFE7),
            backgroundImage: report.photoUrl.trim().isNotEmpty
                ? NetworkImage(report.photoUrl)
                : null,
            onBackgroundImageError:
                report.photoUrl.trim().isNotEmpty ? (_, __) {} : null,
            child: report.photoUrl.trim().isEmpty
                ? const Icon(Icons.pets, size: 18, color: Color(0xFF8A5332))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF2C2420),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Resolved · ${_shortDate(report.timestamp)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A7D75),
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

  static Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeBg,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBECE2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF8A5332)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2420),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A7D75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeBg ?? const Color(0xFFFEEDDE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5A311A),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFFB0A299),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPersistentBottomNav({
    required int activeIndex,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.home_outlined, 'Home', activeIndex == 0,
              onTap: () => onTap(0)),
          _navIcon(Icons.explore_outlined, 'Map', activeIndex == 1,
              onTap: () => onTap(1)),
          _navIcon(Icons.assignment_outlined, 'Reports', activeIndex == 2,
              onTap: () => onTap(2)),
          _navIcon(Icons.person_outline_rounded, 'Profile', activeIndex == 3,
              onTap: () => onTap(3)),
        ],
      ),
    );
  }

  static Widget _navIcon(
    IconData icon,
    String label,
    bool isActive, {
    required VoidCallback onTap,
  }) {
    if (isActive) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE1CC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5A311A)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5A311A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF9E8E84)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E8E84),
              ),
            ),
          ],
        ),
      ),
    );
  }
}