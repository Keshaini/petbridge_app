import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../services/cloudinary_service.dart';
import '../search/map_search_screen.dart';
import 'duplicate_warning_modal.dart';
import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/firestore_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  String? selectedCategory;
  String? selectedAnimalType;

  XFile? selectedImage;
  String? uploadedPhotoUrl;
  String? uploadedPhotoHash;

  bool isUploadingPhoto = false;
  bool isSubmitting = false;

  GeoPoint selectedLocation = const GeoPoint(
    6.8649,
    79.8997,
  );

  String locationLabel = 'Getting current location...';
  String locationAccuracy = 'Please wait while GPS is detected.';

  bool hasValidLocation = false;

  final TextEditingController nameController = TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final List<String> categories = [
    'Lost',
    'Found',
    'Injured',
    'Abandoned',
  ];

  final List<String> animalTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Automatically try to get the device's current location
    // when the Create Report screen opens.
    _getCurrentLocation();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check whether the device's location services are enabled.
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setLocationUnavailable(
          'Location services are turned off. Please adjust the pin.',
        );
        return;
      }

      // Check the current permission status.
      LocationPermission permission =
          await Geolocator.checkPermission();

      // Ask the user for permission if it has not been granted yet.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // The user denied the permission.
      if (permission == LocationPermission.denied) {
        _setLocationUnavailable(
          'Location permission denied. Please adjust the pin.',
        );
        return;
      }

      // The user permanently denied the permission.
      if (permission == LocationPermission.deniedForever) {
        _setLocationUnavailable(
          'Location permission permanently denied. '
          'Please enable it in Settings or adjust the pin.',
        );
        return;
      }

      // Get the current device location.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = GeoPoint(
          position.latitude,
          position.longitude,
        );

        locationLabel = 'Current device location';

        locationAccuracy =
            'GPS accuracy: ±${position.accuracy.toStringAsFixed(0)} m';

        hasValidLocation = true;
      });
    } catch (error) {
      debugPrint('GPS location error: $error');

      _setLocationUnavailable(
        'Unable to detect location. Please adjust the pin.',
      );
    }
  }

  void _setLocationUnavailable(String message) {
    if (!mounted) return;

    setState(() {
      locationLabel = 'Location unavailable';
      locationAccuracy = message;
      hasValidLocation = false;
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null || !mounted) return;

    setState(() {
      selectedImage = pickedFile;
      isUploadingPhoto = true;
      uploadedPhotoUrl = null;
      uploadedPhotoHash = null;
    });

    try {
      // Fingerprint of the picked file, used by the duplicate check.
      final bytes = await pickedFile.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      final url = await CloudinaryService.uploadImage(pickedFile);

      if (!mounted) return;

      setState(() {
        uploadedPhotoUrl = url;
        uploadedPhotoHash = hash;
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo upload failed: $error'),
        ),
      );
    }
  }

  /// Opens the OpenStreetMap picker and updates the selected location.
  Future<void> _adjustPin() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MapSearchScreen(
          selectionMode: true,
          initialLocation: selectedLocation,
          initialLocationLabel: locationLabel,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final location = result['location'];

    if (location is! GeoPoint) return;

    setState(() {
      selectedLocation = location;

      locationLabel =
          result['label'] as String? ?? 'Selected map location';

      locationAccuracy = 'Map coordinates · '
          '${location.latitude.toStringAsFixed(5)}, '
          '${location.longitude.toStringAsFixed(5)}';

      // A manually selected map location is also a valid location.
      hasValidLocation = true;
    });
  }

  Future<void> _onContinue() async {
    if (isSubmitting || isUploadingPhoto) return;

    // Prevent the default placeholder coordinates from being submitted.
    if (!hasValidLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait for GPS or select a location using Adjust pin.',
          ),
        ),
      );
      return;
    }

    if (selectedCategory == null ||
        selectedAnimalType == null ||
        uploadedPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a photo, select a category, '
            'and select an animal type.',
          ),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Duplicate check (FR2). If the check itself fails, log it and let the
      // report through: blocking an animal report is worse than a missed
      // duplicate.
      DuplicateMatch? match;

      try {
        match = await FirestoreService.findDuplicate(
          category: selectedCategory!,
          petName: nameController.text,
          photoHash: uploadedPhotoHash ?? '',
          location: selectedLocation,
        );
      } catch (error) {
        debugPrint('Duplicate check failed: $error');
      }

      if (!mounted) return;

      if (match != null) {
        final bool? isDuplicate = await showDialog<bool>(
          context: context,
          builder: (context) => DuplicateWarningModal(
            existingReportSummary: match!.reason,
            existingReportPhotoUrl:
                match.report.photoUrl.isNotEmpty
                    ? match.report.photoUrl
                    : null,
          ),
        );

        if (!mounted) return;

        // "Yes, same animal" or dismissed:
        // do not create a second report.
        if (isDuplicate == null || isDuplicate == true) {
          return;
        }
      }

      final newReport = ReportModel(
        reportId: '',
        ownerUid: AuthService.currentUid,
        petName: nameController.text.trim(),
        category: selectedCategory!,
        animalType: selectedAnimalType!,
        photoUrl: uploadedPhotoUrl!,
        photoHash: uploadedPhotoHash ?? '',
        location: selectedLocation,
        locationLabel: locationLabel,
        locationRadius: 0.5,
        description: descriptionController.text.trim(),
        status: 'Active',
        timestamp: DateTime.now(),
      );

      await FirestoreService.createReport(
        newReport.toMap(),
      );

      if (!mounted) return;

      context.go('/my-reports');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap:
                          isUploadingPhoto
                              ? null
                              : _pickAndUploadPhoto,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.accentPeach.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child:
                            uploadedPhotoUrl != null &&
                                    !isUploadingPhoto
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    child: Image.network(
                                      uploadedPhotoUrl!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: 160,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stack,
                                          ) =>
                                              const Center(
                                        child: Icon(
                                          Icons
                                              .broken_image_outlined,
                                          color:
                                              AppColors
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
                                          const CircleAvatar(
                                            radius: 22,
                                            backgroundColor:
                                                AppColors
                                                    .accentPeach,
                                            child: Icon(
                                              Icons
                                                  .camera_alt_outlined,
                                              color:
                                                  AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Add a clear photo',
                                            style:
                                                AppTextStyles
                                                    .heading2,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'A photo helps owners '
                                            'identify the pet fast',
                                            style:
                                                AppTextStyles
                                                    .caption,
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
                      children:
                          categories.map((category) {
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
                                color:
                                    selected
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
                          animalTypes.map((animal) {
                            final selected =
                                selectedAnimalType == animal;

                            final IconData animalIcon;

                            switch (animal) {
                              case 'Dog':
                              case 'Cat':
                                animalIcon = Icons.pets;
                              case 'Bird':
                                animalIcon = Icons.air;
                              default:
                                animalIcon =
                                    Icons.category_outlined;
                            }

                            return ChoiceChip(
                              avatar: Icon(
                                animalIcon,
                                size: 18,
                                color:
                                    selected
                                        ? Colors.white
                                        : AppColors
                                            .textSecondary,
                              ),
                              label: Text(animal),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selectedAnimalType = animal;
                                });
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor:
                                  AppColors.cardBackground,
                              labelStyle: TextStyle(
                                color:
                                    selected
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
                        borderRadius: BorderRadius.circular(14),
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
                                  style:
                                      AppTextStyles.bodyText
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
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.accentPeach,
                                      borderRadius:
                                          BorderRadius.circular(
                                              20),
                                    ),
                                    child: const Text(
                                      'Adjust pin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            AppColors
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
                            'Colour, collar, behaviour, '
                            'distinctive marks...',
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
              label:
                  isSubmitting
                      ? 'Submitting...'
                      : 'Continue',
              onPressed:
                  isSubmitting || isUploadingPhoto
                      ? () {}
                      : _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}