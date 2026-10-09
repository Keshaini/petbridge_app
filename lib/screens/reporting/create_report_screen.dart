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
import '../search/map_search_screen.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() =>
      _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  String? selectedCategory;
  String? selectedAnimalType;
  String? selectedBreed;

  XFile? selectedImage;
  String? uploadedPhotoUrl;

  bool isUploadingPhoto = false;
  bool isSubmitting = false;

  // Initial fallback location. Users can change it using the map picker.
  GeoPoint selectedLocation = const GeoPoint(
    6.8649,
    79.8997,
  );

  String locationLabel = 'Nugegoda Junction';
  String locationAccuracy = 'Default location · Please verify';

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

  final List<String> animalTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Other',
  ];

  final Map<String, List<String>> breedsByAnimalType = {
    'Dog': [
      'Mixed Breed',
      'Labrador Retriever',
      'German Shepherd',
      'Golden Retriever',
      'Poodle',
      'Beagle',
      'Bulldog',
      'Rottweiler',
      'Pomeranian',
      'Chihuahua',
      'Siberian Husky',
      'Indian Pariah Dog',
      'Other',
      'Unknown / Not sure',
    ],
    'Cat': [
      'Mixed Breed',
      'Persian',
      'Siamese',
      'British Shorthair',
      'Maine Coon',
      'Bengal',
      'Ragdoll',
      'Domestic Shorthair',
      'Domestic Longhair',
      'Other',
      'Unknown / Not sure',
    ],
    'Bird': [
      'Parrot',
      'Parakeet / Budgerigar',
      'Cockatiel',
      'Lovebird',
      'Pigeon',
      'Crow',
      'Myna',
      'Sparrow',
      'Other',
      'Unknown / Not sure',
    ],
    'Rabbit': [
      'Holland Lop',
      'Netherland Dwarf',
      'Lionhead',
      'Rex',
      'Dutch Rabbit',
      'Other',
      'Unknown / Not sure',
    ],
    'Other': [
      'Unknown / Not sure',
      'Other',
    ],
  };

  List<String> get availableBreeds {
    if (selectedAnimalType == null) {
      return [];
    }

    return breedsByAnimalType[selectedAnimalType] ??
        ['Other', 'Unknown / Not sure'];
  }

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
      final url = await CloudinaryService.uploadImage(pickedFile);

      if (!mounted) return;

      setState(() {
        uploadedPhotoUrl = url;
        isUploadingPhoto = false;
      });

      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo upload failed, please try again',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => isUploadingPhoto = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo upload failed: $error'),
        ),
      );
    }
  }

  Future<void> _adjustPin() async {
    final result = await Navigator.of(context)
        .push<Map<String, dynamic>>(
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

      locationAccuracy =
          'Map coordinates · '
          '${location.latitude.toStringAsFixed(5)}, '
          '${location.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _onContinue() async {
    if (isSubmitting || isUploadingPhoto) return;

    if (selectedCategory == null ||
        uploadedPhotoUrl == null ||
        selectedAnimalType == null ||
        selectedBreed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a photo and select a category, '
            'animal type, and breed.',
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
        final bool? isDuplicate = await showDialog<bool>(
          context: context,
          builder: (context) => DuplicateWarningModal(
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
        animalType: selectedAnimalType!,
        breed: selectedBreed!,
        location: selectedLocation,
        locationRadius: 0.5,
        locationLabel: locationLabel,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading2,
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList();
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
              'Step 1 of 3 · Photo & Details',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          borderRadius: BorderRadius.circular(16),
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
                                  errorBuilder:
                                      (context, error, stack) =>
                                          const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color:
                                          AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isUploadingPhoto)
                                      const CircularProgressIndicator(
                                        color: AppColors.primary,
                                      )
                                    else ...[
                                      const CircleAvatar(
                                        radius: 22,
                                        backgroundColor:
                                            AppColors.accentPeach,
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Add a clear photo',
                                        style:
                                            AppTextStyles.heading2,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'A photo helps owners identify the pet fast',
                                        style:
                                            AppTextStyles.caption,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('What are you reporting?'),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((cat) {
                        final selected = selectedCategory == cat;

                        return ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = cat;
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
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Animal Type'),
                    const SizedBox(height: 12),

                    _buildDropdown(
                      hint: 'Select animal type',
                      value: selectedAnimalType,
                      items: animalTypes,
                      icon: Icons.pets_outlined,
                      onChanged: (value) {
                        setState(() {
                          selectedAnimalType = value;
                          selectedBreed = null;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Breed'),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the breed if you know it.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),

                    _buildDropdown(
                      hint: selectedAnimalType == null
                          ? 'Select animal type first'
                          : 'Select breed',
                      value: selectedBreed,
                      items: availableBreeds,
                      icon: Icons.category_outlined,
                      onChanged: selectedAnimalType == null
                          ? (_) {}
                          : (value) {
                              setState(() {
                                selectedBreed = value;
                              });
                            },
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Pet Name (optional)'),
                    const SizedBox(height: 12),

                    AppTextField(
                      hintText: "Pet's name, if known",
                      icon: Icons.pets_outlined,
                      controller: nameController,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Where was it seen?'),
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
                                  style: AppTextStyles.bodyText
                                      .copyWith(
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
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentPeach,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Adjust pin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppColors.textPrimary,
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

                    _buildSectionTitle('Description (optional)'),
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