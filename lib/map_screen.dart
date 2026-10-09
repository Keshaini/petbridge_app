import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class PetReport {
  final String name;
  final String breed;
  final String status;
  final String timeAgo;
  final String distance;
  final double topPos;
  final double leftPos;

  PetReport({
    required this.name,
    required this.breed,
    required this.status,
    required this.timeAgo,
    required this.distance,
    required this.topPos,
    required this.leftPos,
  });
}

class _MapScreenState extends State<MapScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _locationStatus = 'Fetching active reports near you...';

  final List<PetReport> _allReports = [
    PetReport(
      name: 'Milo',
      breed: 'Golden Retriever',
      status: 'Lost',
      timeAgo: 'seen 2h ago',
      distance: '0.4 km',
      topPos: 180,
      leftPos: 120,
    ),
    PetReport(
      name: 'Simba',
      breed: 'Persian Cat',
      status: 'Found',
      timeAgo: 'seen 4h ago',
      distance: '1.2 km',
      topPos: 320,
      leftPos: 240,
    ),
    PetReport(
      name: 'Rocky',
      breed: 'German Shepherd',
      status: 'Injured',
      timeAgo: 'seen 1h ago',
      distance: '0.8 km',
      topPos: 420,
      leftPos: 90,
    ),
    PetReport(
      name: 'Coco',
      breed: 'Beagle',
      status: 'Lost',
      timeAgo: 'seen 30m ago',
      distance: '1.5 km',
      topPos: 260,
      leftPos: 280,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        _locationStatus = 'Location services disabled.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = 'Location permission denied.';
        });
        return;
      }
    }

    await Geolocator.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      _locationStatus = '5 active reports near you';
    });
  }

  @override
  Widget build(BuildContext context) {
    List<PetReport> filteredReports = _allReports.where((report) {
      bool matchesCategory =
          _selectedCategory == 'All' ||
          report.status.toLowerCase() ==
              _selectedCategory.toLowerCase();

      bool matchesSearch =
          report.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
          report.breed.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: Stack(
        children: [
          // 1. Map Background Grid & Pins
          Container(
            color: const Color(0xFFEFECE6),
            child: Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                  ),
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE4DFD5),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),

                for (var report in filteredReports)
                  Positioned(
                    top: report.topPos,
                    left: report.leftPos,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D2314),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            report.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF5C3A21),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 2. Top Header, Search Bar, and Tabs
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello, Safa',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2314),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationStatus,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A6B5D),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EBE1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFEEDCCF),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            context.go('/profile');
                          },
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF5C3A21),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE4DFD5),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        icon: Icon(
                          Icons.search,
                          color: Color(0xFF5C3A21),
                        ),
                        hintText:
                            'Search area or pet name...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9E8B7C),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter Chips
                  Row(
                    children: ['All', 'Lost', 'Found', 'Injured']
                        .map(
                          (category) {
                            bool isSelected =
                                _selectedCategory ==
                                    category;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                right: 8.0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory =
                                        category;
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFF5C3A21,
                                          )
                                        : const Color(
                                            0xFFF5EBE1,
                                          ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(20),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(
                                              0xFF5C3A21,
                                            ),
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Add Button (+)
          Positioned(
            right: 24,
            bottom: 180,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFE38B75),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                context.push('/create-report');
              },
            ),
          ),

          // 4. Bottom Selected Pet Card & Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (filteredReports.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE4DFD5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EBE1),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Color(0xFF5C3A21),
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${filteredReports.first.name} — ${filteredReports.first.breed}',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      Color(0xFF3D2314),
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: const Color(
                                        0xFFE38B75,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(4),
                                    ),
                                    child: Text(
                                      filteredReports
                                          .first.status
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 5),

                                  Expanded(
                                    child: Text(
                                      '${filteredReports.first.distance} · ${filteredReports.first.timeAgo}',
                                      style:
                                          const TextStyle(
                                        fontSize: 11,
                                        color: Color(
                                          0xFF7A6B5D,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF5C3A21),
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Viewing details for ${filteredReports.first.name}',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'View',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Bottom Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF6F0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE4DFD5),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        Icons.home_outlined,
                        'Home',
                        true,
                        () {
                          context.go('/home');
                        },
                      ),
                      _buildNavItem(
                        Icons.location_on_outlined,
                        'Map',
                        false,
                        () {
                          context.go('/map-search');
                        },
                      ),
                      _buildNavItem(
                        Icons.article_outlined,
                        'Reports',
                        false,
                        () {
                          context.go('/my-reports');
                        },
                      ),
                      _buildNavItem(
                        Icons.person_outline,
                        'Profile',
                        false,
                        () {
                          context.go('/profile');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            color: isSelected
                ? const Color(0xFF5C3A21)
                : const Color(0xFF9E8B7C),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF5C3A21)
                  : const Color(0xFF9E8B7C),
            ),
          ),
        ],
      ),
    );
  }
}