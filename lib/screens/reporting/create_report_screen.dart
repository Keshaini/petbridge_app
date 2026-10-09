
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/report_model.dart';
import 'duplicate_warning_modal.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() =>
      _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  String? selectedCategory;
  String? selectedAnimalType;
  XFile? selectedImage;
  String? uploadedPhotoUrl;

  bool isUploadingPhoto = false;
  bool isSubmitting = false;

  // Location selected using the full-screen Google Maps picker.
  LatLng? selectedLocation;
  String locationLabel = 'No location selected';
  String locationAccuracy =
      'Tap Adjust pin to select the pet location';

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();

  final List<String> categories = [
    'Lost',
    'Found',
    'Injured',
    'Abandoned',
  ];

  // Rabbit is intentionally excluded.
  final List<String> animalTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Other',
  ];

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null || !mounted) return;

    setState(() {
      selectedImage = pickedFile;
      isUploadingPhoto = true;
      uploadedPhotoUrl = null;
    });

    try {
      final url =
          await CloudinaryService.uploadImage(pickedFile);

      if (!mounted) return;

      setState(() {
        uploadedPhotoUrl = url;
        isUploadingPhoto = false;
      });

      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo upload failed, please try again.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isUploadingPhoto = false;
        uploadedPhotoUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo upload failed: $error'),
        ),
      );
    }
  }

  // Opens the original full-screen Google Maps picker.
  Future<void> _adjustPin() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: selectedLocation,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedLocation = result;
      locationLabel = 'Selected location';
      locationAccuracy =
          'Lat ${result.latitude.toStringAsFixed(5)}, '
          'Lng ${result.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _onContinue() async {
    if (isSubmitting || isUploadingPhoto) return;

    if (selectedCategory == null ||
        uploadedPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a photo and select a category.',
          ),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the pet location using Adjust pin.',
          ),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final existingReport =
          await FirestoreService.checkForDuplicate(
        selectedCategory!,
      );

      if (!mounted) return;

      if (existingReport != null) {
        final bool? isDuplicate =
            await showDialog<bool>(
          context: context,
          builder: (dialogContext) =>
              DuplicateWarningModal(
            existingReportSummary:
                'A report matching this animal was submitted recently nearby.',
            existingReportPhotoUrl:
                existingReport.photoUrl.isNotEmpty
                    ? existingReport.photoUrl
                    : null,
          ),
        );

        if (!mounted) return;

        if (isDuplicate == null || isDuplicate == true) {
          return;
        }
      }

      final newReport = ReportModel(
        reportId: '',
        ownerUid: AuthService.currentUid,
        petName: nameController.text.trim(),
        category: selectedCategory!,
        photoUrl: uploadedPhotoUrl!,
        location: GeoPoint(
          selectedLocation!.latitude,
          selectedLocation!.longitude,
        ),
        locationRadius: 0.5,
        description: descriptionController.text.trim(),
        status: 'Active',
        timestamp: DateTime.now(),
      );

      await FirestoreService.createReport(
        newReport.toMap(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully.'),
        ),
      );

      context.pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit report: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Report a Pet',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppColors.border,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.33,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.statusLost,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Step 1 of 3 · Photo & Category',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: isUploadingPhoto
                          ? null
                          : _pickAndUploadPhoto,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.accentPeach
                              .withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: uploadedPhotoUrl != null &&
                                !isUploadingPhoto
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(16),
                                child: Image.network(
                                  uploadedPhotoUrl!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 160,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) =>
                                      const Center(
                                    child: Icon(
                                      Icons
                                          .broken_image_outlined,
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    if (isUploadingPhoto)
                                      const CircularProgressIndicator(
                                        color:
                                            AppColors.primary,
                                      )
                                    else ...[
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor:
                                            AppColors
                                                .accentPeach,
                                        child: const Icon(
                                          Icons
                                              .camera_alt_outlined,
                                          color:
                                              AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        'Add a clear photo',
                                        style: AppTextStyles
                                            .heading2,
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        'A photo helps owners identify the pet fast',
                                        style: AppTextStyles
                                            .caption,
                                        textAlign:
                                            TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'What are you reporting?',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((category) {
                        final selected =
                            selectedCategory == category;

                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor:
                              AppColors.cardBackground,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            side: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Animal Type',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          animalTypes.map((animalType) {
                        final selected =
                            selectedAnimalType == animalType;

                        return ChoiceChip(
                          label: Text(animalType),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              selectedAnimalType = animalType;
                            });
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor:
                              AppColors.cardBackground,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            side: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Pet Name (optional)',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      hintText: "Pet's name, if known",
                      icon: Icons.pets_outlined,
                      controller: nameController,
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Where was it seen?',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.accentPeach
                                  .withOpacity(0.4),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationLabel,
                                  style: AppTextStyles.bodyText
                                      .copyWith(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  locationAccuracy,
                                  style:
                                      AppTextStyles.caption,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _adjustPin,
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.accentPeach,
                                      borderRadius:
                                          BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: const Text(
                                      'Adjust pin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: AppColors
                                            .textPrimary,
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

                    const SizedBox(height: 24),
                    Text(
                      'Description (optional)',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Colour, collar, behaviour, distinctive marks...',
                        filled: true,
                        fillColor:
                            AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: isSubmitting
                  ? 'Submitting...'
                  : 'Continue',
              onPressed: isSubmitting
                  ? () {}
                  : _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Original full-screen Google Maps picker.
/// Tap the map to place or move the pin, then confirm.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  final LatLng? initialLocation;

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState
    extends State<LocationPickerScreen> {
  static const LatLng _fallbackLocation =
      LatLng(6.8649, 79.8997);

  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on your phone location services.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'Location permission was denied. '
          'You can tap the map to choose a location.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is blocked. Enable it '
          'in your phone settings, or tap the map.',
        );
        return;
      }

      final position =
          await Geolocator.getCurrentPosition();

      final current = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() => _pickedLocation = current);

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(current, 16),
      );
    } catch (_) {
      _showMessage(
        'Could not get your location. '
        'You can tap the map to choose it.',
      );
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startLocation =
        _pickedLocation ?? _fallbackLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Pet Location'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton(
            onPressed: _pickedLocation == null
                ? null
                : () {
                    Navigator.of(context)
                        .pop(_pickedLocation);
                  },
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: startLocation,
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (location) {
                setState(() {
                  _pickedLocation = location;
                });
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              markers: _pickedLocation == null
                  ? <Marker>{}
                  : {
                      Marker(
                        markerId: const MarkerId(
                          'selected-pet-location',
                        ),
                        position: _pickedLocation!,
                        infoWindow: const InfoWindow(
                          title: 'Pet location',
                        ),
                      ),
                    },
              mapToolbarEnabled: false,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _pickedLocation == null
                      ? 'Tap the map to drop a pin where the pet was seen.'
                      : 'Pin selected. Move it by tapping another place on the map.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: _gettingLocation
                  ? null
                  : _useCurrentLocation,
              icon: _gettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _gettingLocation
                    ? 'Locating...'
                    : 'Use my location',
              ),
            ),
          ),
        ],
      ),
    );
  }
}