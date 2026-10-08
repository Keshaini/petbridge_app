import 'package:flutter/material.dart';

class SightingReportDetailScreen extends StatefulWidget {
  const SightingReportDetailScreen({super.key});

  @override
  State<SightingReportDetailScreen> createState() =>
      _SightingReportDetailScreenState();
}

class _SightingReportDetailScreenState
    extends State<SightingReportDetailScreen> {
  bool isBookmarked = false;
  bool isResolved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================================
                    // DOG PHOTO / HERO SECTION
                    // =====================================================
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 280,
                          color: const Color(0xFFF1ECE6),
                          child: Image.asset(
                            'assets/images/milo.jpeg',
                            width: double.infinity,
                            height: 280,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Back button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _roundButton(
                            icon: Icons.arrow_back,
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),

                        // Bookmark button
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _roundButton(
                            icon: isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            onTap: () {
                              setState(() {
                                isBookmarked = !isBookmarked;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isBookmarked
                                        ? 'Report bookmarked'
                                        : 'Bookmark removed',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // =====================================================
                    // REPORT INFORMATION
                    // =====================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verified reporter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F4EA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color(0xFF4D7C57),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Verified Reporter',
                                  style: TextStyle(
                                    color: Color(0xFF4D7C57),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Dog name
                          const Text(
                            'Milo',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF292524),
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Golden Retriever',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF78716C),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // LOST badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE7E7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'LOST',
                              style: TextStyle(
                                color: Color(0xFFC24141),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // =================================================
                          // STAT CARDS
                          // =================================================
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: isResolved
                                      ? Icons.check_circle_outline
                                      : Icons.access_time,
                                  title: isResolved ? 'Resolved' : 'Active',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.location_on_outlined,
                                  title: '0.4 km',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.schedule,
                                  title: '2h ago',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =================================================
                          // SIGHTING AREA
                          // =================================================
                          const Text(
                            'Sighting Area',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF292524),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            height: 190,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E2D9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.map_outlined,
                                    size: 60,
                                    color: Color(0xFF8B8177),
                                  ),
                                ),

                                Positioned(
                                  left: 16,
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Downtown Core · 500 m radius',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Directions
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Directions will be available soon',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.directions_outlined),
                              label: const Text('Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4D7C57),
                                side: const BorderSide(
                                  color: Color(0xFF4D7C57),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // =================================================
                          // REPORTER INFORMATION
                          // =================================================
                          const Text(
                            'Reporter',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF292524),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE7E1DA),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE6DED4),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF85786D),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Anjali P.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: Color(0xFF4D7C57),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Verified reporter',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B645E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // =================================================
                          // ACTION BUTTONS
                          // =================================================
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: isResolved
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Messaging will be available soon',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text(
                                'Message Reporter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4D7C57),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFB8C5BA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: isResolved
                                  ? null
                                  : _showResolveDialog,
                              icon: Icon(
                                isResolved
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                              ),
                              label: Text(
                                isResolved
                                    ? 'Resolved'
                                    : 'Mark as Resolved',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF4D7C57),
                                disabledForegroundColor:
                                    const Color(0xFF8A938C),
                                side: BorderSide(
                                  color: isResolved
                                      ? const Color(0xFFB8C5BA)
                                      : const Color(0xFF4D7C57),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // ROUND BUTTON
  // =====================================================
  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: const Color(0xFF292524),
            size: 21,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // STAT CARD
  // =====================================================
  Widget _buildStatCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7E1DA),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF4D7C57),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF57504A),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // RESOLVE DIALOG
  // =====================================================
  void _showResolveDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mark as resolved?'),
          content: const Text(
            'Are you sure this sighting report has been resolved?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isResolved = true;
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report marked as resolved'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D7C57),
                foregroundColor: Colors.white,
              ),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
  }
}