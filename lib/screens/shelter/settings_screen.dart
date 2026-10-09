import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _reportUpdatesEnabled = true;
  bool _rescueAlertsEnabled = true;
  bool _hideExactAddress = true;
  bool _shareUsageData = false;

  double _locationRadius = 10;
  String _selectedLanguage = 'English (US)';

  static const Color _background = Color(0xFFFFF9F6);
  static const Color _brown = Color(0xFF6F3F24);
  static const Color _darkText = Color(0xFF2C2420);
  static const Color _mutedText = Color(0xFF8A7D75);
  static const Color _cardBackground = Colors.white;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showLanguageDialog() async {
    const languages = ['English (US)', 'සිංහල', 'தமிழ்'];

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Choose language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((language) {
              return RadioListTile<String>(
                value: language,
                groupValue: _selectedLanguage,
                activeColor: _brown,
                title: Text(language),
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedLanguage = selected);

      _showMessage(
        selected == 'English (US)'
            ? 'Language preference set to English.'
            : 'Language preference saved. Full app translation '
                  'requires localization support.',
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out of PetBridge?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brown),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService.signOut();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to log out. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _darkText,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _sectionTitle('PREFERENCES'),
            const SizedBox(height: 10),

            _settingsCard(
              children: [
                _navigationRow(
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: _selectedLanguage,
                  onTap: _showLanguageDialog,
                ),
                _divider(),
                _switchRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle: 'Receive PetBridge notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;

                      if (!value) {
                        _reportUpdatesEnabled = false;
                        _rescueAlertsEnabled = false;
                      }
                    });
                  },
                ),
                if (_notificationsEnabled) ...[
                  _divider(),
                  _switchRow(
                    icon: Icons.assignment_outlined,
                    title: 'Report updates',
                    subtitle: 'Updates about your submitted reports',
                    value: _reportUpdatesEnabled,
                    onChanged: (value) {
                      setState(() => _reportUpdatesEnabled = value);
                    },
                  ),
                  _divider(),
                  _switchRow(
                    icon: Icons.pets_outlined,
                    title: 'Rescue alerts',
                    subtitle: 'Alerts about nearby animals in need',
                    value: _rescueAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _rescueAlertsEnabled = value);
                    },
                  ),
                ],
                _divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.radar_rounded,
                            color: _brown,
                            size: 21,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Location radius',
                              style: TextStyle(
                                color: _darkText,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${_locationRadius.round()} km',
                            style: const TextStyle(
                              color: _brown,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set how far away rescue alerts should appear.',
                        style: TextStyle(color: _mutedText, fontSize: 12),
                      ),
                      Slider(
                        value: _locationRadius,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        activeColor: _brown,
                        label: '${_locationRadius.round()} km',
                        onChanged: (value) {
                          setState(() => _locationRadius = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle('PRIVACY & SECURITY'),
            const SizedBox(height: 10),

            _settingsCard(
              children: [
                _switchRow(
                  icon: Icons.location_on_outlined,
                  title: 'Hide exact address',
                  subtitle: 'Show an approximate location on reports',
                  value: _hideExactAddress,
                  onChanged: (value) {
                    setState(() => _hideExactAddress = value);
                  },
                ),
                _divider(),
                _switchRow(
                  icon: Icons.analytics_outlined,
                  title: 'Share usage data',
                  subtitle: 'Help improve the PetBridge experience',
                  value: _shareUsageData,
                  onChanged: (value) {
                    setState(() => _shareUsageData = value);
                  },
                ),
                _divider(),
                _navigationRow(
                  icon: Icons.security_outlined,
                  title: 'Data permissions',
                  subtitle: 'Manage your privacy preferences',
                  onTap: () {
                    _showMessage(
                      'Detailed data permission management is '
                      'not implemented yet.',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle('SUPPORT'),
            const SizedBox(height: 10),

            _settingsCard(
              children: [
                _navigationRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Help centre',
                  subtitle: 'Get help using PetBridge',
                  onTap: () {
                    _showMessage('The Help Centre will be available soon.');
                  },
                ),
                _divider(),
                _navigationRow(
                  icon: Icons.policy_outlined,
                  title: 'Terms & Privacy',
                  subtitle: 'Review our policies',
                  onTap: () {
                    _showMessage(
                      'Terms and Privacy information will be '
                      'available soon.',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // LOGOUT
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _showLogoutDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDDD9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log Out',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFFD32F2F),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                'PetBridge Rescue Network · v2.4.1',
                style: TextStyle(color: _mutedText, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: _mutedText,
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 56, color: Color(0xFFF3ECE6));
  }

  Widget _navigationRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: _leadingIcon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: _darkText,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: _mutedText),
            ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: Color(0xFFB0A299),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: _brown,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey.shade300,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      secondary: _leadingIcon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: _darkText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: _mutedText),
      ),
    );
  }

  Widget _leadingIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBECE2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: _brown),
    );
  }
}
