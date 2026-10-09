import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ============================================================================
/// SCREEN 3: APP SETTINGS SCREEN
/// File: lib/screens/shelter/settings_screen.dart
/// ============================================================================

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool notificationsEnabled = true;
  double locationRadius = 5.0;
  bool hideExactAddress = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================================
              // HEADER
              // =================================================================
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF2C2420),
                      ),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C2420),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =================================================================
              // PREFERENCES
              // =================================================================
              _buildSectionTitle('PREFERENCES'),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // -----------------------------------------------------------
                    // LANGUAGE
                    // -----------------------------------------------------------
                    ListTile(
                      leading: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF6F3F24),
                      ),
                      title: const Text(
                        'Language',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Interface language',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8E8178),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'English',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8178),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF8E8178),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showComingSoon('Language selection');
                      },
                    ),

                    const Divider(
                      height: 1,
                      indent: 60,
                      color: Color(0xFFF3ECE6),
                    ),

                    // -----------------------------------------------------------
                    // NOTIFICATIONS
                    // -----------------------------------------------------------
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF6F3F24),
                      ),
                      title: const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Push alerts for nearby reports',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8E8178),
                        ),
                      ),
                      trailing: Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: notificationsEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF42332B),
                          onChanged: (val) {
                            setState(() {
                              notificationsEnabled = val;
                            });
                          },
                        ),
                      ),
                    ),

                    const Divider(
                      height: 1,
                      indent: 60,
                      color: Color(0xFFF3ECE6),
                    ),

                    // -----------------------------------------------------------
                    // LOCATION RADIUS
                    // -----------------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        14,
                        16,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF6F3F24),
                              ),

                              const SizedBox(width: 14),

                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Location radius',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  Text(
                                    'Alerts within this distance',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF8E8178),
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              Text(
                                '${locationRadius.toInt()} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF6F3F24),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF42332B),
                              inactiveTrackColor:
                                  const Color(0xFFE8DCD4),
                              thumbColor: const Color(0xFF42332B),
                              overlayColor: const Color(0x2942332B),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: locationRadius,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              onChanged: (val) {
                                setState(() {
                                  locationRadius = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================================
              // PRIVACY
              // =================================================================
              _buildSectionTitle('PRIVACY'),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // -----------------------------------------------------------
                    // HIDE EXACT ADDRESS
                    // -----------------------------------------------------------
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF6F3F24),
                      ),
                      title: const Text(
                        'Hide my exact address',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Only a general area is shown to others',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8E8178),
                        ),
                      ),
                      trailing: Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: hideExactAddress,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF42332B),
                          onChanged: (val) {
                            setState(() {
                              hideExactAddress = val;
                            });
                          },
                        ),
                      ),
                    ),

                    const Divider(
                      height: 1,
                      indent: 60,
                      color: Color(0xFFF3ECE6),
                    ),

                    // -----------------------------------------------------------
                    // DATA PERMISSIONS
                    // -----------------------------------------------------------
                    ListTile(
                      leading: const Icon(
                        Icons.security_rounded,
                        color: Color(0xFF6F3F24),
                      ),
                      title: const Text(
                        'Data permissions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF8E8178),
                      ),
                      onTap: () {
                        _showComingSoon('Data permissions');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================================
              // ABOUT
              // =================================================================
              _buildSectionTitle('ABOUT'),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // -----------------------------------------------------------
                    // HELP CENTRE
                    // -----------------------------------------------------------
                    ListTile(
                      title: const Text(
                        'Help centre',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF8E8178),
                      ),
                      onTap: () {
                        _showComingSoon('Help centre');
                      },
                    ),

                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF3ECE6),
                    ),

                    // -----------------------------------------------------------
                    // TERMS & PRIVACY
                    // -----------------------------------------------------------
                    ListTile(
                      title: const Text(
                        'Terms & Privacy Policy',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF8E8178),
                      ),
                      onTap: () {
                        _showComingSoon('Terms & Privacy Policy');
                      },
                    ),

                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF3ECE6),
                    ),

                    // -----------------------------------------------------------
                    // APP VERSION
                    // -----------------------------------------------------------
                    const ListTile(
                      title: Text(
                        'App version',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        '1.0.4 (build 22)',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8E8178),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // =================================================================
              // LOG OUT
              // =================================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFC87D55),
                      width: 1.5,
                    ),
                    backgroundColor: const Color(0xFFFFF2E9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: () {
                    _showLogoutDialog();
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC87D55),
                    ),
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
  // SECTION TITLE
  // ==========================================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Color(0xFF8E8178),
        ),
      ),
    );
  }

  // ==========================================================================
  // COMING SOON MESSAGE
  // ==========================================================================

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================================
  // LOGOUT CONFIRMATION
  // ==========================================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF9F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Log Out?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C2420),
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of PetBridge?',
            style: TextStyle(
              color: Color(0xFF6E5F57),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6F3F24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F3F24),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}