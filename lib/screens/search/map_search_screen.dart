
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/firestore_service.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({
    super.key,
    this.initialLocation,
    this.initialLocationLabel,
    this.selectionMode = false,
  });

  final GeoPoint? initialLocation;
  final String? initialLocationLabel;

  /// True when opened from Create Report to select a pet's location.
  /// False preserves the normal nearby-report search screen.
  final bool selectionMode;

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
  bool _isResolvingAddress = false;

  // Prevents an older address lookup from overwriting a newer selection.
  int _addressRequestId = 0;

  List<ReportModel> _filteredReports = const [];
  List<ReportModel> _latestReports = const [];

  final TextEditingController _locationController =
      TextEditingController();

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

    _showLocationPicker =
        widget.selectionMode || widget.initialLocation == null;

    _showFilters =
        !widget.selectionMode && widget.initialLocation != null;
  }

  @override
  void dispose() {
    _addressRequestId++;
    _locationController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    final today = DateTime.now();

    setState(() {
      _category = _defaultCategory;
      _distance = _defaultDistance;
      _dateRange = _defaultDateRange;
      _species = null;

      _selectedDateRange = DateTimeRange(
        start: today.subtract(const Duration(days: 7)),
        end: today,
      );
    });
  }

  void _applyFilters() {
    if (_selectedLocation == null) return;

    final reports = _reportsForSelectedFilters(_latestReports);

    setState(() {
      _showFilters = false;
      _filteredReports = reports;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${reports.length} reports found near '
            '${_locationLabel ?? 'selected location'}',
          ),
        ),
      );
  }

  Future<void> _selectDateRange() async {
    final today = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
      initialDateRange: _selectedDateRange,
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

  List<ReportModel> _reportsForSelectedFilters(
    List<ReportModel> reports,
  ) {
    final location = _selectedLocation;

    if (location == null) return const [];

    return reports.where((report) {
      final categoryMatches = _category == _defaultCategory ||
          report.category == _category;

      final distanceMatches =
          _distanceBetween(location, report.location) <=
              _distance * 1000;

      final dateMatches = _selectedDateRange == null ||
          (!report.timestamp.isBefore(_selectedDateRange!.start) &&
              !report.timestamp.isAfter(
                _selectedDateRange!.end
                    .add(const Duration(days: 1))
                    .subtract(const Duration(microseconds: 1)),
              ));

      final speciesMatches = _species == null ||
          _species!.isEmpty ||
          report.petName.toLowerCase().contains(
                _species!.toLowerCase(),
              );

      return report.status.toLowerCase() != 'resolved' &&
          categoryMatches &&
          distanceMatches &&
          dateMatches &&
          speciesMatches;
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

      if (!mounted) return;

      final location = GeoPoint(
        position.latitude,
        position.longitude,
      );

      if (widget.selectionMode) {
        await _selectMapPoint(
          LatLng(position.latitude, position.longitude),
        );
      } else {
        _setLocation(location, 'Current location');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not use current location: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _searchLocation() async {
    final query = _locationController.text.trim();

    if (query.isEmpty || _isSearching) return;

    FocusScope.of(context).unfocus();

    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.https(
          'nominatim.openstreetmap.org',
          '/search',
          {
            'q': query,
            'format': 'jsonv2',
            'limit': '1',
          },
        ),
        headers: const {
          'User-Agent': 'PetBridge/1.0 contact@petbridge.app',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Location search failed (${response.statusCode}).',
        );
      }

      final results = jsonDecode(response.body) as List<dynamic>;

      if (results.isEmpty) {
        throw Exception('No matching location found.');
      }

      final result = results.first as Map<String, dynamic>;

      if (!mounted) return;

      final location = GeoPoint(
        double.parse(result['lat'] as String),
        double.parse(result['lon'] as String),
      );

      final label = _formatPlaceName(result);

      if (widget.selectionMode) {
        await _selectMapPoint(
          LatLng(location.latitude, location.longitude),
          fallbackLabel: label,
        );
      } else {
        _setLocation(location, label);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not search location: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  /// Selects a map point and looks up a readable address for it.
  Future<void> _selectMapPoint(
    LatLng point, {
    String? fallbackLabel,
  }) async {
    final location = GeoPoint(
      point.latitude,
      point.longitude,
    );

    final requestId = ++_addressRequestId;

    final fallback = fallbackLabel ??
        'Selected location '
            '(${point.latitude.toStringAsFixed(5)}, '
            '${point.longitude.toStringAsFixed(5)})';

    setState(() {
      _selectedLocation = location;
      _locationLabel = fallbackLabel ?? 'Finding place name...';
      _isResolvingAddress = true;
      _showLocationPicker = false;
      _showFilters = false;
      _filteredReports = const [];
    });

    try {
      final response = await http.get(
        Uri.https(
          'nominatim.openstreetmap.org',
          '/reverse',
          {
            'lat': point.latitude.toString(),
            'lon': point.longitude.toString(),
            'format': 'jsonv2',
            'addressdetails': '1',
            'zoom': '18',
          },
        ),
        headers: const {
          'User-Agent': 'PetBridge/1.0 contact@petbridge.app',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Address lookup failed.');
      }

      final result =
          jsonDecode(response.body) as Map<String, dynamic>;

      final label = _formatPlaceName(result);

      if (!mounted || requestId != _addressRequestId) return;

      setState(() {
        _locationLabel = label;
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (!mounted || requestId != _addressRequestId) return;

      setState(() {
        _locationLabel = fallback;
        _isResolvingAddress = false;
      });
    }
  }

  /// Creates a concise, readable address from a Nominatim result.
  String _formatPlaceName(Map<String, dynamic> result) {
    final address = result['address'];

    if (address is! Map<String, dynamic>) {
      final name = result['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }

      final displayName = result['display_name'] as String?;
      if (displayName != null && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }

      return 'Selected map location';
    }

    final parts = <String>[];

    void addPart(dynamic value) {
      if (value is String &&
          value.trim().isNotEmpty &&
          !parts.contains(value.trim())) {
        parts.add(value.trim());
      }
    }

    addPart(
      address['road'] ??
          address['pedestrian'] ??
          address['footway'],
    );

    addPart(
      address['neighbourhood'] ??
          address['suburb'] ??
          address['quarter'],
    );

    addPart(
      address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'],
    );

    addPart(address['state']);
    addPart(address['country']);

    if (parts.isNotEmpty) {
      return parts.take(4).join(', ');
    }

    final displayName = result['display_name'] as String?;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    return 'Selected map location';
  }

  void _setLocation(GeoPoint location, String label) {
    // Invalidate any previous reverse-geocoding request.
    _addressRequestId++;

    setState(() {
      _selectedLocation = location;
      _locationLabel = label;
      _isResolvingAddress = false;
      _showLocationPicker = false;
      _showFilters =
          !widget.selectionMode && _selectedLocation != null;
      _filteredReports = const [];
    });
  }

  void _openLocationPicker() {
    setState(() {
      _showLocationPicker = true;
      _showFilters = false;
    });
  }

  void _confirmLocation() {
    final location = _selectedLocation;

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop<Map<String, dynamic>>({
      'location': location,
      'label': _locationLabel ?? 'Selected map location',
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
                  reports: widget.selectionMode
                      ? const []
                      : _latestReports,
                  selectedLocation: _selectedLocation,
                  onMapTap: widget.selectionMode
                      ? _selectMapPoint
                      : null,
                ),
              ),

              // Top search bar.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    0,
                  ),
                  child: _SearchBar(
                    label: _locationLabel ??
                        'Search area or pet name',
                    onTap: _openLocationPicker,
                  ),
                ),
              ),

              // Search for a place or use the device location.
              if (_showLocationPicker)
                _LocationPicker(
                  controller: _locationController,
                  isLocating: _isLocating,
                  isSearching: _isSearching,
                  onCurrentLocation: _useCurrentLocation,
                  onSearch: _searchLocation,
                  selectionMode: widget.selectionMode,
                  onCancel: widget.selectionMode
                      ? () => Navigator.of(context).pop()
                      : null,
                ),

              // Confirmation panel in location-picker mode.
              if (widget.selectionMode &&
                  !_showLocationPicker &&
                  _selectedLocation != null)
                _ConfirmLocation(
                  label: _locationLabel ?? 'Selected location',
                  location: _selectedLocation!,
                  isResolvingAddress: _isResolvingAddress,
                  onChangeLocation: _openLocationPicker,
                  onConfirm: _confirmLocation,
                ),

              // Existing report search filters.
              if (!widget.selectionMode && _showFilters)
                DraggableScrollableSheet(
                  initialChildSize: 0.64,
                  minChildSize: 0.34,
                  maxChildSize: 0.84,
                  snap: true,
                  snapSizes: const [0.34, 0.64, 0.84],
                  builder: (context, scrollController) =>
                      _FilterSheet(
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

              // Existing nearby report results.
              if (!widget.selectionMode &&
                  !_showFilters &&
                  !_showLocationPicker &&
                  _selectedLocation != null)
                _ReportResults(
                  reports: _filteredReports,
                  locationLabel: _locationLabel ?? 'Selected location',
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
    this.onMapTap,
  });

  final List<ReportModel> reports;
  final GeoPoint? selectedLocation;
  final ValueChanged<LatLng>? onMapTap;

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
        : LatLng(
            selectedLocation!.latitude,
            selectedLocation!.longitude,
          );

    final markers = <Marker>[
      ...reports.map(
        (report) => Marker(
          point: LatLng(
            report.location.latitude,
            report.location.longitude,
          ),
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
              Icons.location_on,
              size: 34,
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
            initialZoom: selectedLocation == null ? 12 : 15,
            onTap: (tapPosition, point) {
              onMapTap?.call(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
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
  const _SearchBar({
    required this.label,
    required this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 23,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
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
    required this.selectionMode,
    this.onCancel,
  });

  final TextEditingController controller;
  final bool isLocating;
  final bool isSearching;
  final VoidCallback onCurrentLocation;
  final VoidCallback onSearch;
  final bool selectionMode;
  final VoidCallback? onCancel;

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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Choose a location',
                          style: _headingStyle,
                        ),
                      ),
                      if (selectionMode)
                        IconButton(
                          onPressed: onCancel,
                          icon: const Icon(Icons.close),
                          tooltip: 'Cancel',
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectionMode
                        ? 'Search for a place or tap directly on the map to mark where the pet was seen.'
                        : 'Pick your current location or search for an area to find nearby reports.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
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
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: onSearch,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                              ),
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
                      onPressed:
                          isLocating ? null : onCurrentLocation,
                      icon: isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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

class _ConfirmLocation extends StatelessWidget {
  const _ConfirmLocation({
    required this.label,
    required this.location,
    required this.isResolvingAddress,
    required this.onChangeLocation,
    required this.onConfirm,
  });

  final String label;
  final GeoPoint location;
  final bool isResolvingAddress;
  final VoidCallback onChangeLocation;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm pet location',
                style: _headingStyle,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (isResolvingAddress) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Latitude: ${location.latitude.toStringAsFixed(6)}\n'
                'Longitude: ${location.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (isResolvingAddress) ...[
                const SizedBox(height: 5),
                const Text(
                  'Finding the place name…',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onChangeLocation,
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Use location'),
                    ),
                  ),
                ],
              ),
            ],
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
                    'No active reports match these filters. '
                    'Try increasing the distance or changing the category.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    shrinkWrap: true,
                    itemCount: reports.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final report = reports[index];

                      return ListTile(
                        onTap: () => context.push(
                          '/report-detail/${report.reportId}',
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
                              ? const Icon(
                                  Icons.pets,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        title: Text(
                          report.petName.isEmpty
                              ? 'Pet report'
                              : report.petName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${report.category} · '
                          '${_formatReportDate(report.timestamp)}',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                        ),
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

  static const _categories = [
    'All',
    'Lost',
    'Found',
    'Injured',
    'Abandoned',
  ];

  static const _speciesOptions = [
    'Dog',
    'Cat',
    'Bird',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 18,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
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
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
              ),
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
          _DateField(
            dateRange: dateRange,
            onPressed: onDatePressed,
          ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
  Widget build(BuildContext context) {
    return Text(label, style: _sectionStyle);
  }
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
                color: value == selected
                    ? Colors.white
                    : AppColors.textPrimary,
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
  const _DateField({
    required this.dateRange,
    required this.onPressed,
  });

  final String dateRange;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 7, 7, 7),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE5D9CC),
        ),
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