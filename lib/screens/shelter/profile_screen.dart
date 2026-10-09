
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';

/// ============================================================================
/// USER PROFILE OVERVIEW SCREEN
/// File: lib/screens/shelter/profile_screen.dart
/// ============================================================================

class UserProfileOverviewScreen extends StatelessWidget {
  const UserProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // MAIN SCROLLABLE CONTENT
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // APP BAR HEADER
                  Row(
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
                  ),

                  const SizedBox(height: 18),

                  // PROFILE PHOTO + LIVE USER INFORMATION
                  Center(
                    child: StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(AuthService.currentUid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();

                        final rawName = data?['name'] as String?;
                        final name = rawName?.trim();

                        final rawPhotoUrl = data?['photoUrl'] as String?;
                        final photoUrl = rawPhotoUrl?.trim();

                        final rawLocation = data?['location'] as String?;
                        final location = rawLocation?.trim();

                        final hasPhoto =
                            photoUrl != null && photoUrl.isNotEmpty;

                        return Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: hasPhoto
                                        ? Image.network(
                                            photoUrl,
                                            width: 92,
                                            height: 92,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return _defaultProfileImage();
                                            },
                                          )
                                        : Image.asset(
                                            'assets/images/my_profile.png',
                                            width: 92,
                                            height: 92,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return _defaultProfileImage();
                                            },
                                          ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: InkWell(
                                    onTap: () =>
                                        context.push('/edit-profile'),
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

                            // Name + verified badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    name == null || name.isEmpty
                                        ? 'PetBridge user'
                                        : name,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2C2420),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6F0E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        size: 11,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Active Community Rescuer · Member since Oct 2023'
                              '\n${location == null || location.isEmpty ? 'Pinecrest Gardens' : location}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF8A7D75),
                                height: 1.3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NEIGHBORHOOD HERO BANNER
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Neighborhood Hero · Lvl 3',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: Color(0xFF2C2420),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '5 more verified rescues to unlock '
                                    'the Golden Collar award!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF4C3E36),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '9/14',
                              style: TextStyle(
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
                          child: const LinearProgressIndicator(
                            value: 9 / 14,
                            backgroundColor: Color(0x80FFFFFF),
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF5A311A),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PROFILE METRICS
                  Row(
                    children: [
                      _buildMetricTile(
                        Icons.assignment_outlined,
                        '14',
                        'Reports Made',
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        Icons.volunteer_activism_outlined,
                        '9',
                        'Animals Helped',
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        Icons.verified_user_outlined,
                        '98%',
                        'Trust Score',
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // RECENT RESCUES
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
                        child: const Text(
                          'See all (9)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBA5D43),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildRescueCard(
                          'https://images.unsplash.com/'
                          'photo-1552053831-71594a27632d?w=200',
                          'Barnaby',
                          'Adopted · Oct 24',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRescueCard(
                          'https://images.unsplash.com/'
                          'photo-1514888286974-6c03e2ca1dba?w=200',
                          'Mochi',
                          'Fostered · Nov 02',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ACCOUNT & PREFERENCES
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
                          badge: '3 active',
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
                          title: 'Notification Settings',
                          hasDot: true,
                          onTap: () => context.push('/settings'),
                        ),

                        _settingsDivider(),

                        _buildSettingsRow(
                          icon: Icons.translate_rounded,
                          title: 'Language',
                          subtitle: 'English (US)',
                          onTap: () => context.push('/settings'),
                        ),

                        _settingsDivider(),

                        _buildSettingsRow(
                          icon: Icons.handshake_outlined,
                          title: 'Affiliated Shelters',
                          badge: '2 Connected',
                          badgeBg: const Color(0xFFD6F0E0),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Affiliated Shelters will be available soon.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LOG OUT
                  InkWell(
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
                              content: Text(
                                'Unable to log out. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                  ),

                  const SizedBox(height: 20),

                  // FOOTER
                  const Center(
                    child: Text(
                      '♡ PetBridge Rescue Network · v2.4.1\n'
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

            // PERSISTENT BOTTOM NAVIGATION
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

  // DEFAULT PROFILE IMAGE
  static Widget _defaultProfileImage() {
    return Container(
      color: const Color(0xFFFCEFE7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 48,
        color: Color(0xFF9E8E84),
      ),
    );
  }

  // SETTINGS DIVIDER
  static Widget _settingsDivider() {
    return const Divider(
      height: 1,
      indent: 56,
      color: Color(0xFFF3ECE6),
    );
  }

  // METRIC TILE
  static Widget _buildMetricTile(
    IconData icon,
    String value,
    String title,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF8A5332),
            ),
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

  // RECENT RESCUE CARD
  static Widget _buildRescueCard(
    String imageUrl,
    String name,
    String tag,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(imageUrl),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF2C2420),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tag,
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

  // SETTINGS ROW
  static Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeBg,
    bool hasDot = false,
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
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF8A5332),
          ),
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
            if (hasDot)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(left: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF6F3F24),
                  shape: BoxShape.circle,
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

  // BOTTOM NAVIGATION
  static Widget _buildPersistentBottomNav({
    required int activeIndex,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(
            Icons.home_outlined,
            'Home',
            activeIndex == 0,
            onTap: () => onTap(0),
          ),
          _navIcon(
            Icons.explore_outlined,
            'Map',
            activeIndex == 1,
            onTap: () => onTap(1),
          ),
          _navIcon(
            Icons.assignment_outlined,
            'Reports',
            activeIndex == 2,
            onTap: () => onTap(2),
          ),
          _navIcon(
            Icons.person_outline_rounded,
            'Profile',
            activeIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }

  // NAVIGATION ITEM
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
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE1CC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF5A311A),
              ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF9E8E84),
            ),
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