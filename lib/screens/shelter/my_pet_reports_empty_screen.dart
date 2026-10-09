import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ============================================================================
/// SCREEN 7: MY PET REPORTS — EMPTY STATE
/// File: lib/screens/my_pet_reports_empty_screen.dart
/// ============================================================================

class MyPetReportsEmptyScreen extends StatelessWidget {
  const MyPetReportsEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================================
                  // APP BAR
                  // ==========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.pop();
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

                      Column(
                        children: const [
                          Text(
                            'My Pet Reports',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C2420),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Track your lost & found alerts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A7D75),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCEFE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: Color(0xFF6F3F24),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==========================================================
                  // ACTIVE / RESOLVED TOGGLE
                  // ==========================================================
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEDDE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A311A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Resolved',
                                style: TextStyle(
                                  color: Color(0xFF7A6B63),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1DECF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '0',
                                  style: TextStyle(
                                    color: Color(0xFF7A6B63),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ==========================================================
                  // EMPTY STATE ILLUSTRATION
                  // ==========================================================
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFCE2D1),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.pets_rounded,
                              size: 70,
                              color: const Color(0xFFC87D55)
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 14,
                          right: 18,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD6F0E0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 18,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDD5B7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets,
                              size: 14,
                              color: Color(0xFF8A5332),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================================
                  // TITLE + DESCRIPTION
                  // ==========================================================
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEEDDE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.circle,
                                size: 7,
                                color: Color(0xFF8A5332),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Community Rescue Grid',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8A5332),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'No reports yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C2420),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Reports you create will appear here. When you report a lost or found companion in your neighborhood, you can track volunteer sightings and case updates right from this screen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Color(0xFF6E5F57),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ==========================================================
                  // CREATE FIRST REPORT
                  // ==========================================================
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A311A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        context.push('/create-report');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Create Your First Report',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==========================================================
                  // BROWSE NEARBY LOST PETS
                  // ==========================================================
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nearby lost pets will be available here.',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.travel_explore_rounded,
                            size: 16,
                            color: Color(0xFF5A311A),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Browse nearby lost pets',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A311A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================================
                  // QUICK ASSISTANCE
                  // ==========================================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDD5B7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: Color(0xFF8A5332),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'QUICK ASSISTANCE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF8A5332),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tip: Anyone can report a lost or found pet in under 60 seconds with just a photo and pin location. Alerts broadcast instantly to neighbors within a 5-mile radius.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Color(0xFF54443B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ================================================================
            // PERSISTENT BOTTOM NAVIGATION
            // ================================================================
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildPersistentBottomNav(
                activeIndex: 2,
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

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================

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

  static Widget _navIcon(
    IconData icon,
    String label,
    bool isActive, {
    required VoidCallback onTap,
  }) {
    final Widget content;

    if (isActive) {
      content = Container(
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
      );
    } else {
      content = Column(
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
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}