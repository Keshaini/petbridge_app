import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/report_model.dart';
import 'duplicate_warning_modal.dart';

class MapSearchScreen extends StatelessWidget {
  const MapSearchScreen({
    super.key,
    required this.selectionMode,
    required this.initialLocation,
    required this.initialLocationLabel,
  });

  final bool selectionMode;
  final GeoPoint initialLocation;
  final String initialLocationLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select location'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Map location picker',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the current report pin for this demo: $initialLocationLabel',
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Use this location',
                onPressed: () => Navigator.of(context).pop({
                  'location': initialLocation,
                  'label': initialLocationLabel,
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  bool isUploadingPhoto = false;
  bool isSubmitting = false;

  GeoPoint selectedLocation = const GeoPoint(6.8649, 79.8997);
  String locationLabel = 'Nugegoda Junction';
  String locationAccuracy = 'GPS pin dropped · ±20 m accuracy';

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
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
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

      final url = await CloudinaryService.uploadImage(pickedFile);

      if (!mounted) return;

      setState(() {
        uploadedPhotoUrl = url;
        isUploadingPhoto = false;
      });

      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed, please try again'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => isUploadingPhoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload photo: $error')),
      );
    }
  }

  Future<void> _adjustPin() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => MapSearchScreen(
          selectionMode: true,
          initialLocation: selectedLocation,
          initialLocationLabel: locationLabel,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result is Map) {
      final location = result['location'];
      final label = result['label'];

      if (location is GeoPoint) {
        setState(() {
          selectedLocation = location;

          if (label is String && label.trim().isNotEmpty) {
            locationLabel = label;
          }

          locationAccuracy = 'Location selected on map';
        });
      }
    }
  }

  Future<void> _onContinue() async {
    if (uploadedPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo before continuing.'),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a report category.'),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    if (selectedAnimalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an animal type.'),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    if (isSubmitting || isUploadingPhoto) return;

    setState(() => isSubmitting = true);

    try {
      final existingReport =
          await FirestoreService.checkForDuplicate(selectedCategory!);

      if (!mounted) return;

      if (existingReport != null) {
        final bool? isDuplicate = await showDialog<bool>(
          context: context,
          builder: (context) => DuplicateWarningModal(
            existingReportSummary:
                'A report matching this animal was submitted recently nearby.',
            existingReportPhotoUrl: existingReport.photoUrl.isNotEmpty
                ? existingReport.photoUrl
                : null,
          ),
        );

        if (!mounted) return;

        if (isDuplicate == null || isDuplicate == true) {
          setState(() => isSubmitting = false);
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
        location: selectedLocation,
        locationLabel: locationLabel,
        locationRadius: 0.5,
        description: descriptionController.text.trim(),
        status: 'Active',
        timestamp: DateTime.now(),
      );

      await FirestoreService.createReport(newReport.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
        ),
      );

      context.pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Widget _buildAnimalTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAnimalType,
          isExpanded: true,
          hint: const Text('Select animal type'),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: animalTypes.map((animalType) {
            return DropdownMenuItem<String>(
              value: animalType,
              child: Row(
                children: [
                  const Icon(
                    Icons.pets_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(animalType),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedAnimalType = value;
            });
          },
        ),
      ),
    );
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
                      onTap: isUploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.accentPeach.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: isUploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : uploadedPhotoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      uploadedPhotoUrl!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: 160,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              AppColors.accentPeach,
                                          child: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Add a clear photo',
                                          style: AppTextStyles.heading2,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'A photo helps owners identify the pet fast',
                                          style: AppTextStyles.caption,
                                          textAlign: TextAlign.center,
                                        ),
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
                        final bool selected =
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
                          backgroundColor: AppColors.cardBackground,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
                    _buildAnimalTypeDropdown(),
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
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accentPeach.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationLabel,
                                  style: AppTextStyles.bodyText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  locationAccuracy,
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _adjustPin,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentPeach,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Adjust pin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
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
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
              label: isSubmitting ? 'Submitting...' : 'Continue',
              onPressed: isSubmitting || isUploadingPhoto
                  ? () {}
                  : _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}