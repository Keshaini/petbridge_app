import 'package:flutter/material.dart';

/// ============================================================================
/// SCREEN: ANIMAL CASE INTAKE DETAIL SCREEN
/// File: lib/screens/shelter/case_intake.dart
///
/// Dog image:
/// assets/images/rusty.jpeg
/// ============================================================================

class CaseIntakeDetailScreen extends StatefulWidget {
  const CaseIntakeDetailScreen({super.key});

  @override
  State<CaseIntakeDetailScreen> createState() =>
      _CaseIntakeDetailScreenState();
}

class _CaseIntakeDetailScreenState extends State<CaseIntakeDetailScreen> {
  bool isBookmarked = false;
  bool isClaimed = false;
  bool isResolved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============================================================
              // TOP BAR
              // =============================================================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEDDE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🏥 Case #PB-4028 · Staff Portal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF844D29),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Shelter Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF246D32),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Material(
                    color: const Color(0xFFFEEFE6),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          isBookmarked = !isBookmarked;
                        });

                        _showMessage(
                          isBookmarked
                              ? 'Case bookmarked'
                              : 'Bookmark removed',
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 20,
                          color: const Color(0xFF6F3F24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =============================================================
              // HERO PET CARD
              // =============================================================
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  height: 280,
                  color: const Color(0xFFF1E8DF),
                  child: Stack(
                    children: [
                      // -----------------------------------------------------
                      // DOG IMAGE
                      // BoxFit.contain = ENTIRE PHOTO REMAINS VISIBLE
                      // -----------------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 280,
                        child: Image.asset(
                          'assets/images/milo.jpeg',
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pets_rounded,
                                    size: 55,
                                    color: Color(0xFF9A8475),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Dog image not found',
                                    style: TextStyle(
                                      color: Color(0xFF7A6A60),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // -----------------------------------------------------
                      // LOST TIME / ID CHIP
                      // -----------------------------------------------------
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Color(0xFF2C2420),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Lost 2d ago · ID #84920',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C2420),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // -----------------------------------------------------
                      // URGENT CHIP
                      // -----------------------------------------------------
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 7,
                                height: 7,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFC73E1D),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '✱ Urgent · Needs Daily Meds',
                                style: TextStyle(
                                  color: Color(0xFFC73E1D),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
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

              const SizedBox(height: 16),

              // =============================================================
              // TITLE + GENDER
              // =============================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Rusty',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C2420),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDD5B7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '♂ Male · Neutered',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7A4624),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              const Text(
                'Golden Retriever · 3 yrs · 65 lbs',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6E6057),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // =============================================================
              // LOCATION CHIP
              // =============================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEDDE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFF8A5332),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Pinecrest Community Park, North Gate trail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C3D34),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =============================================================
              // METRIC STATS
              // =============================================================
              Row(
                children: [
                  _buildStatCard(
                    'Status',
                    isResolved
                        ? 'Resolved'
                        : isClaimed
                            ? 'Claimed'
                            : 'Active\nSearch',
                    const Color(0xFF8A5332),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    'Urgency',
                    '! High',
                    const Color(0xFFC73E1D),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    'Reported',
                    '2 hrs ago',
                    const Color(0xFF2C2420),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =============================================================
              // CLINICAL DETAILS CARD
              // =============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------------------------------------------------------
                    // HEADER
                    // -------------------------------------------------------
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEEDDE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            size: 20,
                            color: Color(0xFF8A5332),
                          ),
                        ),

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C2420),
                                ),
                              ),
                              Text(
                                'Veterinary & Intake Records',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8C7F78),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEEDDE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Staff Only',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A5332),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // =======================================================
                    // MICROCHIP CARD
                    // =======================================================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_rounded,
                                    size: 16,
                                    color: Color(0xFF6F3F24),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Microchip ID',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6F3F24),
                                    ),
                                  ),
                                ],
                              ),

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
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 10,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '985-141-002-839-441',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2C2420),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    _showMessage(
                                      'Microchip ID copied',
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.copy_rounded,
                                          size: 12,
                                          color: Color(0xFF6F3F24),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6F3F24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =======================================================
                    // MEDICAL & BEHAVIORAL NOTES
                    // =======================================================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEEDDE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_information_outlined,
                                size: 16,
                                color: Color(0xFF8A5332),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Medical & Behavioral Notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8A5332),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Requires daily insulin: Caninsulin 8 IU morning dose before meals. Patient has mild left hind leg hip dysplasia. Non-aggressive, friendly temperament but exhibits stress shaking around heavy vehicular noise.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: Color(0xFF3F322B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =======================================================
                    // GUARDIAN CARD
                    // =======================================================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFFFDD5B7),
                                child: Text(
                                  'EV',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF7A4624),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Elena Vance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2C2420),
                                      ),
                                    ),
                                    Text(
                                      'Verified Pet Guardian',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8A7D75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Text(
                                '+1 (555) 349-2091',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6F3F24),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // Call Guardian
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor:
                                        const Color(0xFF2C2420),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      side: const BorderSide(
                                        color: Color(0xFFE8DCD4),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showMessage(
                                      'Calling Elena Vance...',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Call Guardian',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Send SMS
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFFDC59B),
                                    foregroundColor:
                                        const Color(0xFF6F3F24),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showMessage(
                                      'Opening SMS to Elena Vance...',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Send SMS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =======================================================
                    // SHELTER WARD
                    // =======================================================
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _showMessage(
                            'Shelter ward details selected',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6F0E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  size: 18,
                                  color: Color(0xFF246D32),
                                ),
                              ),

                              const SizedBox(width: 12),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned Shelter Ward',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF8A7D75),
                                      ),
                                    ),
                                    Text(
                                      'Sunny Meadows Humane Society · Ward 2B',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C2420),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF8A7D75),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =============================================================
              // CLAIM INTAKE CASE BUTTON
              // =============================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClaimed
                        ? const Color(0xFF4D7C57)
                        : const Color(0xFF6F3F24),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: isResolved
                      ? null
                      : () {
                          setState(() {
                            isClaimed = true;
                          });

                          _showMessage(
                            'Intake case claimed successfully',
                          );
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isClaimed
                            ? Icons.check_circle_rounded
                            : Icons.assignment_turned_in_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isClaimed
                            ? 'Case Claimed'
                            : 'Claim Intake Case',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =============================================================
              // MARK CASE AS RESOLVED
              // =============================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEEDDE),
                    side: BorderSide.none,
                    disabledBackgroundColor:
                        const Color(0xFFEDE8E3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: isResolved
                      ? null
                      : _showResolveDialog,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isResolved
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: isResolved
                            ? const Color(0xFF4D7C57)
                            : const Color(0xFF6F3F24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isResolved
                            ? 'Case Resolved'
                            : 'Mark Case as Resolved',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isResolved
                              ? const Color(0xFF4D7C57)
                              : const Color(0xFF6F3F24),
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

  // ==========================================================================
  // STAT CARD
  // ==========================================================================

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A7D75),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // RESOLVE DIALOG
  // ==========================================================================

  void _showResolveDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Mark Case as Resolved?',
          ),
          content: const Text(
            'Are you sure this intake case has been resolved?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F3F24),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isResolved = true;
                });

                Navigator.pop(dialogContext);

                _showMessage(
                  'Case marked as resolved',
                );
              },
              child: const Text(
                'Resolve',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // SNACKBAR HELPER
  // ==========================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}