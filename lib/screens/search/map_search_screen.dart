import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../screens/reporting/report_detail_screen.dart';
import '../../services/firestore_service.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({
    super.key,
    this.initialLocation,
    this.initialLocationLabel,
  });

  final GeoPoint? initialLocation;
  final String? initialLocationLabel;

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  static const _defaultCategory = 'All';
  static const _defaultDistance = 9.0;
  static const _defaultDateRange = 'Last 7 days';

  String _category = _defaultCategory;
  double _distance = _defaultDistance;
  String _dateRange = _defaultDateRange;
  String? _species;
  DateTimeRange? _selectedDateRange;
  GeoPoint? _selectedLocation;
  String? _locationLabel;
  bool _showFilters = false;
  bool _showLocationPicker = true;
  bool _isLocating = false;
  bool _isSearching = false;
  List<ReportModel> _filteredReports = const [];
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: today.subtract(const Duration(days: 7)),
      end: today,
    );
    _selectedLocation = widget.initialLocation;
    _locationLabel = widget.initialLocationLabel;
    _showLocationPicker = widget.initialLocation == null;
    _showFilters = widget.initialLocation != null;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _category = _defaultCategory;
      _distance = _defaultDistance;
      _dateRange = _defaultDateRange;
      _species = null;
      final today = DateTime.now();
      _selectedDateRange = DateTimeRange(
        start: today.subtract(const Duration(days: 7)),
        end: today,
      );
    });
  }

  void _applyFilters() {
    final location = _selectedLocation;
    if (location == null) return;

    final reports = _reportsForSelectedFilters(_latestReports);
    setState(() => _showFilters = false);
    setState(() => _filteredReports = reports);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${reports.length} reports found near $_locationLabel'),
        ),
      );
  }

  Future<void> _selectDateRange() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: today.subtract(const Duration(days: 7)),
        end: today,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            surface: AppColors.cardBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    final days = picked.end.difference(picked.start).inDays + 1;
    setState(() {
      _selectedDateRange = picked;
      _dateRange = 'Last $days days';
    });
  }

  List<ReportModel> _latestReports = const [];

  List<ReportModel> _reportsForSelectedFilters(List<ReportModel> reports) {
    final location = _selectedLocation;
    if (location == null) return const [];
    return reports.where((report) {
      final categoryMatches =
          _category == _defaultCategory || report.category == _category;
      final distanceMatches =
          _distanceBetween(location, report.location) <= _distance * 1000;
      final dateMatches =
          _selectedDateRange == null ||
          !report.timestamp.isBefore(_selectedDateRange!.start) &&
              !report.timestamp.isAfter(
                _selectedDateRange!.end
                    .add(const Duration(days: 1))
                    .subtract(const Duration(microseconds: 1)),
              );
      return report.status.toLowerCase() != 'resolved' &&
          categoryMatches &&
          distanceMatches &&
          dateMatches;
    }).toList();
  }

  double _distanceBetween(GeoPoint first, GeoPoint second) {
    return Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      second.latitude,
      second.longitude,
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      _setLocation(
        GeoPoint(position.latitude, position.longitude),
        'Current location',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not use current location: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _searchLocation() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': query,
          'format': 'jsonv2',
          'limit': '1',
        }),
        headers: const {'User-Agent': 'PetBridge/1.0 contact@petbridge.app'},
      );
      if (response.statusCode != 200) {
        throw Exception('Location search failed (${response.statusCode}).');
      }
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) throw Exception('No matching location found.');
      final result = results.first as Map<String, dynamic>;
      _setLocation(
        GeoPoint(
          double.parse(result['lat'] as String),
          double.parse(result['lon'] as String),
        ),
        result['display_name'] as String,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not search location: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _setLocation(GeoPoint location, String label) {
    setState(() {
      _selectedLocation = location;
      _locationLabel = label;
      _showLocationPicker = false;
      _showFilters = true;
      _filteredReports = const [];
    });
  }

  void _openLocationPicker() {
    setState(() {
      _showLocationPicker = true;
      _showFilters = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ReportModel>>(
        stream: Firebase.apps.isEmpty
            ? Stream.value(const <ReportModel>[])
            : FirestoreService.getActiveReports(),
        builder: (context, snapshot) {
          _latestReports = snapshot.data ?? const [];
          return Stack(
            children: [
              Positioned.fill(
                child: _OpenStreetMapView(
                  reports: _latestReports,
                  selectedLocation: _selectedLocation,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _SearchBar(
                    label: _locationLabel ?? 'Search area or pet name',
                    onTap: _openLocationPicker,
                  ),
                ),
              ),
              if (_showLocationPicker)
                _LocationPicker(
                  controller: _locationController,
                  isLocating: _isLocating,
                  isSearching: _isSearching,
                  onCurrentLocation: _useCurrentLocation,
                  onSearch: _searchLocation,
                ),
              if (_showFilters)
                DraggableScrollableSheet(
                  initialChildSize: 0.64,
                  minChildSize: 0.34,
                  maxChildSize: 0.84,
                  snap: true,
                  snapSizes: const [0.34, 0.64, 0.84],
                  builder: (context, scrollController) => _FilterSheet(
                    scrollController: scrollController,
                    category: _category,
                    distance: _distance,
                    dateRange: _dateRange,
                    species: _species,
                    onCategoryChanged: (value) =>
                        setState(() => _category = value),
                    onDistanceChanged: (value) =>
                        setState(() => _distance = value),
                    onDatePressed: _selectDateRange,
                    onSpeciesChanged: (value) =>
                        setState(() => _species = value),
                    onReset: _resetFilters,
                    onApply: _applyFilters,
                  ),
                ),
              if (!_showFilters &&
                  !_showLocationPicker &&
                  _selectedLocation != null)
                _ReportResults(
                  reports: _filteredReports,
                  locationLabel: _locationLabel!,
                  onChangeLocation: _openLocationPicker,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OpenStreetMapView extends StatelessWidget {
  const _OpenStreetMapView({
    required this.reports,
    required this.selectedLocation,
  });

  final List<ReportModel> reports;
  final GeoPoint? selectedLocation;

  static const _defaultCenter = LatLng(6.8649, 79.8997);

  @override
  Widget build(BuildContext context) {
    final center = selectedLocation == null
        ? (reports.isEmpty
              ? _defaultCenter
              : LatLng(
                  reports.first.location.latitude,
                  reports.first.location.longitude,
                ))
        : LatLng(selectedLocation!.latitude, selectedLocation!.longitude);

    final markers = <Marker>[
      ...reports.map(
        (report) => Marker(
          point: LatLng(report.location.latitude, report.location.longitude),
          width: 42,
          height: 42,
          child: const Icon(
            Icons.location_on,
            size: 38,
            color: AppColors.primary,
          ),
        ),
      ),
      if (selectedLocation != null)
        Marker(
          point: center,
          width: 52,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.statusLost.withAlpha(45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location,
              size: 26,
              color: AppColors.statusLost,
            ),
          ),
        ),
    ];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: selectedLocation == null ? 12 : 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.petbridge.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3D9CE),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.primary, size: 23),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.controller,
    required this.isLocating,
    required this.isSearching,
    required this.onCurrentLocation,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isLocating;
  final bool isSearching;
  final VoidCallback onCurrentLocation;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Material(
            color: AppColors.cardBackground,
            elevation: 18,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose a location', style: _headingStyle),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick your current location or search for an area to find nearby reports.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search area or city',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              onPressed: onSearch,
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF5EAE0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLocating ? null : onCurrentLocation,
                      icon: isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: const Text('Use current location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportResults extends StatelessWidget {
  const _ReportResults({
    required this.reports,
    required this.locationLabel,
    required this.onChangeLocation,
  });

  final List<ReportModel> reports;
  final String locationLabel;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 360),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${reports.length} reports near $locationLabel',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onChangeLocation,
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              if (reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Text(
                    'No active reports match these filters. Try increasing the distance or changing the category.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    shrinkWrap: true,
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ListTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ReportDetailScreen(reportId: report.reportId),
                          ),
                        ),
                        tileColor: const Color(0xFFF5EAE0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundImage: report.photoUrl.isNotEmpty
                              ? NetworkImage(report.photoUrl)
                              : null,
                          backgroundColor: AppColors.accentPeach,
                          child: report.photoUrl.isEmpty
                              ? const Icon(Icons.pets, color: AppColors.primary)
                              : null,
                        ),
                        title: Text(
                          report.petName.isEmpty
                              ? 'Pet report'
                              : report.petName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${report.category} · ${_formatReportDate(report.timestamp)}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatReportDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.scrollController,
    required this.category,
    required this.distance,
    required this.dateRange,
    required this.species,
    required this.onCategoryChanged,
    required this.onDistanceChanged,
    required this.onDatePressed,
    required this.onSpeciesChanged,
    required this.onReset,
    required this.onApply,
  });

  final ScrollController scrollController;
  final String category;
  final double distance;
  final String dateRange;
  final String? species;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<double> onDistanceChanged;
  final VoidCallback onDatePressed;
  final ValueChanged<String?> onSpeciesChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  static const _categories = ['All', 'Lost', 'Found', 'Injured', 'Abandoned'];
  static const _speciesOptions = ['Dog', 'Cat', 'Bird', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 18,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFEED9BB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: _headingStyle),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: AppColors.statusLost,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const _SectionLabel('CATEGORY'),
          const SizedBox(height: 10),
          _ChipWrap(
            values: _categories,
            selected: category,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('DISTANCE'),
              Text(
                '${distance.round()} km',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFEED9BB),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(25),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: distance,
              min: 1,
              max: 20,
              onChanged: onDistanceChanged,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: _rangeStyle),
              Text('20+ km', style: _rangeStyle),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('DATE RANGE'),
          const SizedBox(height: 10),
          _DateField(dateRange: dateRange, onPressed: onDatePressed),
          const SizedBox(height: 22),
          const _SectionLabel('SPECIES'),
          const SizedBox(height: 10),
          _ChipWrap(
            values: _speciesOptions,
            selected: species,
            onSelected: onSpeciesChanged,
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 112,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(label, style: _sectionStyle);
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: value == selected,
              onSelected: (_) => onSelected(value),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              side: BorderSide(
                color: value == selected
                    ? AppColors.primary
                    : const Color(0xFFE5D9CC),
              ),
              labelStyle: TextStyle(
                color: value == selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )
          .toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.dateRange, required this.onPressed});

  final String dateRange;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 7, 7),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5D9CC)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textSecondary,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dateRange,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: const Text(
              'Select',
              style: TextStyle(
                color: AppColors.statusLost,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _headingStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 24,
  fontWeight: FontWeight.w800,
);

const _sectionStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 11,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w800,
);

const _rangeStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  fontWeight: FontWeight.w500,
);
