import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _background = Color(0xFFFAF6F0);
  static const _brown = Color(0xFF3E2723);
  static const _muted = Color(0xFF8D7B68);
  static const _peach = Color(0xFFFCEBD9);
  static const _red = Color(0xFFE53935);

  int _selectedTab = 0;
  bool _allRead = false;

  static const _tabs = [
    'All (5)',
    'Sightings (1)',
    'Alerts (2)',
    'Messages',
  ];

  final _notifications = const [
    _NotificationData(
      category: 'Sightings',
      icon: Icons.pets,
      iconBackground: Color(0xFFFFF3DF),
      title: 'New Sighting Alert 🐾',
      time: '8m ago',
      body:
          'Milo (Tabby Cat) was reported seen near Pinecrest Gardens with a fresh photo...',
      tags: ['📍 0.3 mi away', '📷 Photo match 92%'],
      tagColors: [Color(0xFFFCEBD9), Color(0xFFD4EDDA)],
      tagTextColors: [_brown, Color(0xFF287A3E)],
      unread: true,
    ),
    _NotificationData(
      category: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      iconBackground: Color(0xFFFFF3DF),
      title: 'Sunny Meadows Shelter',
      time: '34m ago',
      body:
          "Coordinator Sarah sent you an update regarding adoption application #4028: 'We...",
      action: '↵  Reply now',
      unread: true,
    ),
    _NotificationData(
      category: 'Alerts',
      icon: Icons.campaign_outlined,
      iconBackground: Color(0xFFF8D7DA),
      title: 'Neighborhood Urgent Alert ❗',
      time: '2h ago',
      body:
          'Lost Beagle puppy wearing a red collar reported in North Ridge area. Needs daily...',
      tags: ['🏥 Medical urgency'],
      tagColors: [Color(0xFFF8D7DA)],
      tagTextColors: [Color(0xFF721C24)],
      unread: true,
    ),
    _NotificationData(
      category: 'Alerts',
      icon: Icons.volunteer_activism_outlined,
      iconBackground: Color(0xFFD4EDDA),
      title: 'Reunion Celebration!',
      time: 'Yesterday, 3:20 PM',
      body:
          'Great news! Oliver has been safely reunited with his family thanks to rapid community...',
      action: '♡  48 neighbors cheered',
    ),
    _NotificationData(
      category: 'All',
      icon: Icons.notifications_none_rounded,
      iconBackground: Color(0xFFFFF3DF),
      title: 'Weekly Rescue Digest',
      time: '2 days ago',
      body:
          '3 lost companions were successfully brought home this week in your district. Thanks for...',
    ),
  ];

  List<_NotificationData> get _visibleNotifications {
    if (_selectedTab == 0) return _notifications;
    final category = _tabs[_selectedTab].split(' ').first;
    return _notifications
        .where((notification) => notification.category == category)
        .toList();
  }

  void _markAllRead() {
    setState(() => _allRead = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 20),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  ..._visibleNotifications.map(_buildNotificationCard),
                  const SizedBox(height: 8),
                  _buildSettingsBanner(),
                ],
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.pets, color: _brown, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Home',
            style: TextStyle(
              color: _brown,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_rounded, color: _brown),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.account_circle_outlined, color: _brown),
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  color: _brown,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.circle, color: _red, size: 9),
                  SizedBox(width: 6),
                  Text(
                    '3 new alerts today',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _allRead ? null : _markAllRead,
          style: TextButton.styleFrom(
            backgroundColor: _peach,
            foregroundColor: _brown,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(_allRead ? '✓ All read' : '✓ Mark all read'),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = _selectedTab == index;
          return Padding(
            padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: selected,
              onSelected: (_) => setState(() => _selectedTab = index),
              selectedColor: _brown,
              backgroundColor: const Color(0xFFFFFCF7),
              side: BorderSide(
                color: selected ? _brown : const Color(0xFFE4D5C5),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : _brown,
                fontWeight: FontWeight.w700,
              ),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationData notification) {
    final unread = notification.unread && !_allRead;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEFE2D5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: notification.iconBackground,
                  child: Icon(notification.icon, color: _brown),
                ),
                if (unread)
                  const Positioned(
                    right: -1,
                    top: -2,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: _red,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            color: _brown,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notification.time,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: _muted,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                  if (notification.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: List.generate(
                        notification.tags.length,
                        (index) => _Tag(
                          label: notification.tags[index],
                          color: notification.tagColors[index],
                          textColor: notification.tagTextColors[index],
                        ),
                      ),
                    ),
                  ],
                  if (notification.action != null) ...[
                    const SizedBox(height: 10),
                    _ActionPill(label: notification.action!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/settings'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF0E6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.tune_rounded, color: _brown),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage notification alerts',
                    style: TextStyle(
                      color: _brown,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Customize your rescue radii, push notifications, and sound',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _brown),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, 'Home', () => context.go('/home')),
          _navItem(
            Icons.location_on_outlined,
            'Map',
            () => context.go('/map-search'),
          ),
          _navItem(
            Icons.article_outlined,
            'Reports',
            () => context.go('/my-reports'),
          ),
          _navItem(
            Icons.person_outline,
            'Profile',
            () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _brown),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _brown,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5EBE1),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: _NotificationsScreenState._brown),
        tooltip: 'Back',
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _NotificationsScreenState._brown,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationData {
  const _NotificationData({
    required this.category,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.time,
    required this.body,
    this.tags = const [],
    this.tagColors = const [],
    this.tagTextColors = const [],
    this.action,
    this.unread = false,
  });

  final String category;
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String time;
  final String body;
  final List<String> tags;
  final List<Color> tagColors;
  final List<Color> tagTextColors;
  final String? action;
  final bool unread;
}
