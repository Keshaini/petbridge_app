import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isMarkingAllRead = false;

  static const _tabs = [
    'All',
    'Sightings',
    'Alerts',
    'Messages',
  ];

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _notificationsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('notifications');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _notificationsStream {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _selectedCategory() {
    switch (_selectedTab) {
      case 1:
        return 'Sightings';
      case 2:
        return 'Alerts';
      case 3:
        return 'Messages';
      default:
        return 'All';
    }
  }

  Future<void> _markAllRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    if (_isMarkingAllRead || notifications.isEmpty) return;

    final unread = notifications.where((doc) {
      return doc.data()['isRead'] != true;
    }).toList();

    if (unread.isEmpty) return;

    setState(() => _isMarkingAllRead = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final notification in unread) {
        batch.update(notification.reference, {
          'isRead': true,
        });
      }

      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not mark notifications as read: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  Future<void> _markAsRead(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    if (notification.data()['isRead'] == true) return;

    try {
      await notification.reference.update({
        'isRead': true,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update notification: $e'),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    await _markAsRead(notification);

    if (!mounted) return;

    final data = notification.data();

    final route = data['route'] as String?;

    if (route != null && route.trim().isNotEmpty) {
      context.push(route);
    }
  }

  String _formatTime(dynamic value) {
    DateTime? dateTime;

    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }

    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'sightings':
        return Icons.pets;

      case 'alerts':
        return Icons.campaign_outlined;

      case 'messages':
        return Icons.chat_bubble_outline_rounded;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _iconBackgroundForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'alerts':
        return const Color(0xFFF8D7DA);

      case 'messages':
        return const Color(0xFFFFF3DF);

      case 'sightings':
        return const Color(0xFFFFF3DF);

      default:
        return const Color(0xFFFFF3DF);
    }
  }

  Color _tagTextColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'green':
        return const Color(0xFF287A3E);

      case 'red':
        return const Color(0xFF721C24);

      default:
        return _brown;
    }
  }

  Color _tagBackgroundColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'green':
        return const Color(0xFFD4EDDA);

      case 'red':
        return const Color(0xFFF8D7DA);

      default:
        return _peach;
    }
  }

  int _countCategory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
    String category,
  ) {
    return notifications.where((notification) {
      final value = notification.data()['category'] as String? ?? '';
      return value.toLowerCase() == category.toLowerCase();
    }).length;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _visibleNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) {
    final category = _selectedCategory();

    if (category == 'All') {
      return notifications;
    }

    return notifications.where((notification) {
      final value = notification.data()['category'] as String? ?? '';
      return value.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          foregroundColor: _brown,
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: _brown,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Please sign in to view your notifications.',
            style: TextStyle(color: _muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _brown,
                      ),
                    );
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  final unreadCount = notifications.where((notification) {
                    return notification.data()['isRead'] != true;
                  }).length;

                  final visibleNotifications =
                      _visibleNotifications(notifications);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _buildTitleSection(
                        unreadCount: unreadCount,
                        notifications: notifications,
                      ),
                      const SizedBox(height: 20),
                      _buildTabs(notifications),
                      const SizedBox(height: 16),
                      if (visibleNotifications.isEmpty)
                        _buildEmptyState()
                      else
                        ...visibleNotifications.map(
                          (notification) =>
                              _buildNotificationCard(notification),
                        ),
                      const SizedBox(height: 8),
                      _buildSettingsBanner(),
                    ],
                  );
                },
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _red,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load notifications',
              style: TextStyle(
                color: _brown,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEFE2D5),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: _muted,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: _brown,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'You will see rescue alerts, messages, and sightings here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          const Icon(
            Icons.pets,
            color: _brown,
            size: 24,
          ),
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
            icon: const Icon(
              Icons.notifications_rounded,
              color: _brown,
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(
              Icons.account_circle_outlined,
              color: _brown,
            ),
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection({
    required int unreadCount,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        notifications,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CircleButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  color: _brown,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: unreadCount > 0 ? _red : _muted,
                    size: 9,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unreadCount > 0
                        ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}'
                        : 'All notifications are read',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: unreadCount == 0 || _isMarkingAllRead
              ? null
              : () => _markAllRead(notifications),
          style: TextButton.styleFrom(
            backgroundColor: _peach,
            foregroundColor: _brown,
            disabledForegroundColor: _muted,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isMarkingAllRead
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _brown,
                  ),
                )
              : Text(
                  unreadCount == 0
                      ? '✓ All read'
                      : '✓ Mark all read',
                ),
        ),
      ],
    );
  }

  Widget _buildTabs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) {
    final counts = [
      notifications.length,
      _countCategory(notifications, 'Sightings'),
      _countCategory(notifications, 'Alerts'),
      _countCategory(notifications, 'Messages'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = _selectedTab == index;

          return Padding(
            padding: EdgeInsets.only(
              right: index == _tabs.length - 1 ? 0 : 8,
            ),
            child: ChoiceChip(
              label: Text('${_tabs[index]} (${counts[index]})'),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedTab = index);
              },
              selectedColor: _brown,
              backgroundColor: const Color(0xFFFFFCF7),
              side: BorderSide(
                color: selected
                    ? _brown
                    : const Color(0xFFE4D5C5),
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

  Widget _buildNotificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) {
    final data = notification.data();

    final category = data['category'] as String? ?? 'Alerts';
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final isRead = data['isRead'] == true;

    final tags = List<String>.from(
      data['tags'] ?? const [],
    );

    final tagColors = List<String>.from(
      data['tagColors'] ?? const [],
    );

    return Card(
      elevation: 0,
      color: isRead ? Colors.white : const Color(0xFFFFFCF7),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isRead
              ? const Color(0xFFEFE2D5)
              : const Color(0xFFE6D1B9),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _handleNotificationTap(notification),
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
                    backgroundColor:
                        _iconBackgroundForCategory(category),
                    child: Icon(
                      _iconForCategory(category),
                      color: _brown,
                    ),
                  ),
                  if (!isRead)
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
                            title,
                            style: TextStyle(
                              color: _brown,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(data['createdAt']),
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: const TextStyle(
                          color: _muted,
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: List.generate(
                          tags.length,
                          (index) {
                            final colorName =
                                index < tagColors.length
                                    ? tagColors[index]
                                    : '';

                            return _Tag(
                              label: tags[index],
                              color:
                                  _tagBackgroundColor(colorName),
                              textColor:
                                  _tagTextColor(colorName),
                            );
                          },
                        ),
                      ),
                    ],
                    if (data['action'] != null) ...[
                      const SizedBox(height: 10),
                      _ActionPill(
                        label: data['action'] as String,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.tune_rounded,
                color: _brown,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
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
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _brown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 12,
      ),
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
          _navItem(
            Icons.home_outlined,
            'Home',
            () => context.go('/home'),
          ),
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

  Widget _navItem(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _brown,
            ),
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
  const _CircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5EBE1),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: _NotificationsScreenState._brown,
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
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
  const _ActionPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
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