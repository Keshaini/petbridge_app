import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShelterDashboardScreen extends StatefulWidget {
  const ShelterDashboardScreen({super.key});

  @override
  State<ShelterDashboardScreen> createState() =>
      _ShelterDashboardScreenState();
}

class _ShelterDashboardScreenState extends State<ShelterDashboardScreen> {
  bool urgentOnly = false;

  // ================================================================
  // SHELTER CASES
  // ================================================================

  final List<Map<String, dynamic>> cases = [
    {
      'title': 'Injured Stray',
      'subtitle': 'Intake · 1h ago',
      'badge': 'INJURED',
      'badgeColor': const Color(0xFFC49A45),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/injured_stray.jpeg',
    },
    {
      'title': 'Husky Mix',
      'subtitle': 'Lost · Urgent',
      'badge': 'URGENT',
      'badgeColor': const Color(0xFFBA5D43),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/husky_mix.jpeg',
    },
    {
      'title': 'Domestic Short',
      'subtitle': 'Stray · Open',
      'badge': 'FOUND',
      'badgeColor': const Color(0xFF5A9372),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/domestic_short.jpeg',
    },
    {
      'title': 'Golden Pup',
      'subtitle': 'Unclaimed',
      'badge': 'FOUND',
      'badgeColor': const Color(0xFF5A9372),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/golden_pup.jpeg',
    },
    {
      'title': 'Brown Labrador',
      'subtitle': 'Lost · 2h ago',
      'badge': 'URGENT',
      'badgeColor': const Color(0xFFBA5D43),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/brown_labrador.jpeg',
    },
    {
      'title': 'White Persian',
      'subtitle': 'Found · 3h ago',
      'badge': 'FOUND',
      'badgeColor': const Color(0xFF5A9372),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/white_persian.jpeg',
    },
    {
      'title': 'Black Kitten',
      'subtitle': 'Stray · 5h ago',
      'badge': 'INJURED',
      'badgeColor': const Color(0xFFC49A45),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/black_kitten.jpeg',
    },
    {
      'title': 'Beagle Mix',
      'subtitle': 'Lost · Yesterday',
      'badge': 'URGENT',
      'badgeColor': const Color(0xFFBA5D43),
      'badgeTextColor': Colors.white,
      'image': 'assets/images/beagle_mix.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final displayedCases = urgentOnly
        ? cases.where((item) => item['badge'] == 'URGENT').toList()
        : cases;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ============================================================
            // MAIN SCROLLABLE CONTENT
            // ============================================================

            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  150,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ======================================================
                    // HEADER
                    // ======================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shelter Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2C2420),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kandy Animal Care · Nugegoda',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E8E84),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Notification
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF332924),
                              size: 22,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    100,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  content: const Text(
                                    'No new notifications',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ======================================================
                    // STATISTICS
                    // ======================================================

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            value: '${cases.length}',
                            label: 'Open cases',
                            valueColor: const Color(0xFF2D231E),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            value: '4',
                            label: 'Claimed today',
                            valueColor: const Color(0xFF5A9372),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            value:
                                '${cases.where((item) => item['badge'] == 'URGENT').length}',
                            label: 'Urgent',
                            valueColor: const Color(0xFFBA5D43),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ======================================================
                    // URGENT ONLY
                    // ======================================================

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Urgent only',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D231E),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: urgentOnly,
                              activeColor: Colors.white,
                              activeTrackColor:
                                  const Color(0xFF42332B),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor:
                                  const Color(0xFF42332B),
                              trackOutlineColor:
                                  MaterialStateProperty.all(
                                Colors.transparent,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  urgentOnly = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ======================================================
                    // RECENT CASES HEADER
                    // ======================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Cases',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C2420),
                          ),
                        ),
                        Text(
                          '${displayedCases.length} cases',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E8E84),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ======================================================
                    // CASE GRID
                    // ======================================================

                    if (displayedCases.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 45,
                              color: Color(0xFF5A9372),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No urgent cases',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C2420),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Everything looks good for now.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E8E84),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 18,
                          mainAxisExtent: 360,
                        ),
                        itemCount: displayedCases.length,
                        itemBuilder: (context, index) {
                          return _buildPetCard(
                            displayedCases[index],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // BOTTOM NAVIGATION
            // ============================================================

            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      Icons.home_outlined,
                      'Home',
                      onTap: () => context.go('/home'),
                    ),
                    _buildNavItem(
                      Icons.location_on_outlined,
                      'Map',
                      onTap: () => context.go('/map-search'),
                    ),
                    _buildNavItem(
                      Icons.dashboard_rounded,
                      'Dashboard',
                      isActive: true,
                      onTap: () => context.go('/shelter-dashboard'),
                    ),
                    _buildNavItem(
                      Icons.person_outline_rounded,
                      'Profile',
                      onTap: () => context.go('/profile'),
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

  // ================================================================
  // METRIC CARD
  // ================================================================

  Widget _buildMetricCard({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E8E84),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PET CARD
  // ================================================================

  Widget _buildPetCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // LARGE PET IMAGE
          // ==========================================================

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              item['image'],
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9E7C8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      size: 42,
                      color: Color(0xFFE5C89F),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ==========================================================
          // PET NAME
          // ==========================================================

          Text(
            item['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C2420),
            ),
          ),

          const SizedBox(height: 3),

          // ==========================================================
          // SUBTITLE
          // ==========================================================

          Text(
            item['subtitle'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E8E84),
            ),
          ),

          const SizedBox(height: 7),

          // ==========================================================
          // STATUS BADGE
          // ==========================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: item['badgeColor'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item['badge'],
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: item['badgeTextColor'],
              ),
            ),
          ),

          const Spacer(),

          // ==========================================================
          // CLAIM BUTTON
          // ==========================================================

          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(
                  color: Color(0xFF332924),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    content: Text(
                      '${item['title']} selected',
                    ),
                  ),
                );
              },
              child: const Text(
                'Claim',
                style: TextStyle(
                  color: Color(0xFF332924),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION ITEM
  // ================================================================

  Widget _buildNavItem(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7E7CD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF332924),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF332924),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF9E8E84),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9E8E84),
              ),
            ),
          ],
        ),
      ),
    );
  }
}