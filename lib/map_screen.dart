import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'models/report_model.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color _brown = Color(0xFF5C3A21);
  static const Color _darkBrown = Color(0xFF3D2314);
  static const Color _muted = Color(0xFF7A6B5D);
  static const Color _cream = Color(0xFFFAF6F0);
  static const Color _chipBg = Color(0xFFF5EBE1);
  static const Color _border = Color(0xFFE4DFD5);
  static const Color _coral = Color(0xFFE38B75);

  static const List<String> _categories = [
    'All',
    'Lost',
    'Found',
    'Injured',
    'Abandoned',
  ];

  late final Stream<List<ReportModel>> _reportsStream;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _selectedReportId;
  String? _locationNote;
  String _userName = '';
  Position? _position;

  @override
  void initState() {
    super.initState();
    _reportsStream = FirestoreService.getActiveReports();
    _loadUserName();
    _determinePosition();
  }

  // ---------------------------------------------------------------------------
  // USER NAME
  // ---------------------------------------------------------------------------

  Future<void> _loadUserName() async {
    final uid = AuthService.currentUid;
    if (uid == 'guest') return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final name = (doc.data()?['name'] as String?)?.trim() ?? '';

      if (!mounted) return;
      setState(() => _userName = name);
    } catch (_) {
      // Keep the fallback greeting.
    }
  }

  String get _greetingName {
    if (_userName.isNotEmpty) return _userName.split(' ').first;

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null && email.contains('@')) return email.split('@').first;

    return 'there';
  }

  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------

  Future<void> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _locationNote = 'Location services are turned off.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _locationNote = 'Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(
        () => _locationNote = 'Location permission permanently denied.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() {
        _position = position;
        _locationNote = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationNote = 'Unable to determine your location.');
    }
  }

  double? _distanceKm(ReportModel report) {
    final position = _position;
    if (position == null) return null;

    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          report.location.latitude,
          report.location.longitude,
        ) /
        1000;
  }

  String _distanceLabel(ReportModel report) {
    final km = _distanceKm(report);
    if (km == null) return 'Distance unknown';
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _titleFor(ReportModel report) {
    if (report.petName.trim().isNotEmpty) return report.petName;
    if (report.animalType.trim().isNotEmpty) {
      return '${report.animalType} report';
    }
    return 'Pet report';
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'lost':
        return const Color(0xFFE05B3C);
      case 'found':
        return const Color(0xFF6B8E5A);
      case 'injured':
        return const Color(0xFFD9A441);
      default:
        return _brown;
    }
  }

  List<ReportModel> _applyFilters(List<ReportModel> all) {
    final query = _searchQuery.trim().toLowerCase();

    final list = all.where((report) {
      final matchesCategory = _selectedCategory == 'All' ||
          report.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch = query.isEmpty ||
          report.petName.toLowerCase().contains(query) ||
          report.animalType.toLowerCase().contains(query) ||
          report.category.toLowerCase().contains(query) ||
          report.locationLabel.toLowerCase().contains(query) ||
          report.description.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();

    // Nearest first when we know where the user is.
    if (_position != null) {
      list.sort(
        (a, b) => (_distanceKm(a) ?? 1e9).compareTo(_distanceKm(b) ?? 1e9),
      );
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: StreamBuilder<List<ReportModel>>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          final bool loading =
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;
          final bool hasError = snapshot.hasError;
          final all = snapshot.data ?? <ReportModel>[];
          final filtered = _applyFilters(all);

          ReportModel? selected;
          if (filtered.isNotEmpty) {
            selected = filtered.firstWhere(
              (r) => r.reportId == _selectedReportId,
              orElse: () => filtered.first,
            );
          }

          return Stack(
            children: [
              // 1. Map background and pins
              Positioned.fill(child: _buildMapLayer(filtered, selected)),

              // 2. Header, search and chips
              SafeArea(child: _buildHeader(all.length, loading, hasError)),

              // 3. Add report button
              Positioned(
                right: 24,
                bottom: 190,
                child: FloatingActionButton(
                  backgroundColor: _coral,
                  onPressed: () => context.push('/create-report'),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              // 4. Selected report card and bottom navigation
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBottomCard(
                      selected: selected,
                      loading: loading,
                      hasError: hasError,
                      totalCount: all.length,
                    ),
                    const SizedBox(height: 12),
                    _buildBottomNav(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAP LAYER
  // ---------------------------------------------------------------------------

  Widget _buildMapLayer(List<ReportModel> reports, ReportModel? selected) {
    return Container(
      color: const Color(0xFFEFECE6),
      child: Stack(
        children: [
          Positioned.fill(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _border, width: 0.5),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: _buildPins(reports, selected, box),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Places each report on the stylised grid using its real coordinates,
  /// relative to the user's position (or the middle of the reports when the
  /// position is unknown). Reports at identical coordinates are fanned out
  /// slightly so each pin stays tappable.
  List<Widget> _buildPins(
    List<ReportModel> reports,
    ReportModel? selected,
    BoxConstraints box,
  ) {
    if (reports.isEmpty) return const [];

    const double left = 30;
    const double top = 260;
    final double right = math.max(left + 40, box.maxWidth - 80);
    final double bottom = math.max(top + 40, box.maxHeight - 330);
    final double centerX = (left + right) / 2;
    final double centerY = (top + bottom) / 2;

    double refLat;
    double refLng;
    final position = _position;

    if (position != null) {
      refLat = position.latitude;
      refLng = position.longitude;
    } else {
      refLat = reports
              .map((r) => r.location.latitude)
              .reduce((a, b) => a + b) /
          reports.length;
      refLng = reports
              .map((r) => r.location.longitude)
              .reduce((a, b) => a + b) /
          reports.length;
    }

    const double pxPerKm = 90;
    final double cosLat = math.cos(refLat * math.pi / 180);
    final Map<String, int> seen = {};
    final List<Widget> pins = [];

    if (position != null) {
      pins.add(
        Positioned(
          left: centerX - 9,
          top: centerY - 9,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      );
    }

    for (final report in reports) {
      final key = '${report.location.latitude.toStringAsFixed(4)},'
          '${report.location.longitude.toStringAsFixed(4)}';
      final int n = seen[key] ?? 0;
      seen[key] = n + 1;

      final double dxKm =
          (report.location.longitude - refLng) * 111.32 * cosLat;
      final double dyKm = -(report.location.latitude - refLat) * 110.57;

      double x = centerX + dxKm * pxPerKm;
      double y = centerY + dyKm * pxPerKm;

      if (n > 0) {
        final double radius = 34.0 * ((n + 5) ~/ 6);
        final double angle = n * (math.pi / 3);
        x += math.cos(angle) * radius;
        y += math.sin(angle) * radius;
      }

      x = x.clamp(left, right);
      y = y.clamp(top, bottom);

      final bool isSelected = selected?.reportId == report.reportId;

      pins.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () => setState(() => _selectedReportId = report.reportId),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _categoryColor(report.category) : _darkBrown,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _titleFor(report),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.location_on,
                  color: _categoryColor(report.category),
                  size: isSelected ? 40 : 32,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return pins;
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(int totalCount, bool loading, bool hasError) {
    String subtitle;
    if (hasError) {
      subtitle = 'Unable to load reports';
    } else if (loading) {
      subtitle = 'Loading reports...';
    } else if (_locationNote != null) {
      subtitle = _locationNote!;
    } else {
      subtitle = totalCount == 1
          ? '1 active report near you'
          : '$totalCount active reports near you';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_greetingName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _darkBrown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _circleButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/notifications'),
                  ),
                  const SizedBox(width: 10),
                  _circleButton(
                    icon: Icons.person_outline,
                    tooltip: 'Profile',
                    onPressed: () => context.go('/profile'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: _brown),
                hintText: 'Search area or pet name...',
                hintStyle: TextStyle(color: Color(0xFF9E8B7C), fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((category) {
                final bool isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _brown : _chipBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _chipBg,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEEDCCF)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: _brown),
        tooltip: tooltip,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM CARD
  // ---------------------------------------------------------------------------

  Widget _buildBottomCard({
    required ReportModel? selected,
    required bool loading,
    required bool hasError,
    required int totalCount,
  }) {
    if (loading) {
      return _messageCard(
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _brown),
            ),
            SizedBox(width: 12),
            Text('Loading reports...', style: TextStyle(color: _muted)),
          ],
        ),
      );
    }

    if (hasError) {
      return _messageCard(
        child: const Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: _brown),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not load reports. Check your connection and try again.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (selected == null) {
      return _messageCard(
        child: Row(
          children: [
            const Icon(Icons.pets_outlined, color: _brown),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                totalCount == 0
                    ? 'No active reports yet. Tap + to create the first one.'
                    : 'No reports match your search or filter.',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 56,
              child: selected.photoUrl.trim().isNotEmpty
                  ? Image.network(
                      selected.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.animalType.trim().isNotEmpty
                      ? '${_titleFor(selected)} — ${selected.animalType}'
                      : _titleFor(selected),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _darkBrown,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(selected.category),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        selected.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${_distanceLabel(selected)} · ${_timeAgo(selected.timestamp)}',
                        style: const TextStyle(fontSize: 11, color: _muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () =>
                context.push('/report-detail/${selected.reportId}'),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: _chipBg,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, color: _brown, size: 28),
    );
  }

  Widget _messageCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            'Home',
            true,
            () => context.go('/home'),
          ),
          _buildNavItem(
            Icons.location_on_outlined,
            'Map',
            false,
            () => context.go('/map-search'),
          ),
          _buildNavItem(
            Icons.dashboard_outlined,
            'Dashboard',
            false,
            () => context.go('/shelter-dashboard'),
          ),
          _buildNavItem(
            Icons.article_outlined,
            'Reports',
            false,
            () => context.go('/my-reports'),
          ),
          _buildNavItem(
            Icons.person_outline,
            'Profile',
            false,
            () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? _brown : const Color(0xFF9E8B7C),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? _brown : const Color(0xFF9E8B7C),
            ),
          ),
        ],
      ),
    );
  }
}