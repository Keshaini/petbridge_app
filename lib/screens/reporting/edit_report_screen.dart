import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import 'delete_confirmation_modal.dart';

class EditReportScreen extends StatefulWidget {
  final String reportId;

  const EditReportScreen({super.key, required this.reportId});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  // TODO: replace with real data fetched from Firestore using widget.reportId
  String? selectedType = 'Lost';
  final List<String> reportTypes = ['Lost', 'Found', 'Injured', 'Stray'];

  final TextEditingController nameController =
      TextEditingController(text: 'Rusty');
  final TextEditingController speciesController =
      TextEditingController(text: 'Golden Retriever · Male, Neutered');
  final TextEditingController locationController =
      TextEditingController(text: 'Nugegoda Junction');
  final TextEditingController descriptionController = TextEditingController(
    text: 'Golden coat with white chest patch. Wearing a dark leather '
        'collar with brass bell. Very friendly, answers to Rusty. '
        'Last seen heading towards the park trail near the junction.',
  );

  bool hasMedicalAlert = true;
  int photoCount = 3;

  @override
  void dispose() {
    nameController.dispose();
    speciesController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _changePhoto() {
    // TODO: open image_picker, upload to Firebase Storage once connected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo picker coming soon')),
    );
  }

  void _addMorePhotos() {
    // TODO: open image_picker (multi-select) once connected
    setState(() => photoCount += 1);
  }

  void _adjustPin() {
    // TODO: open google_maps_flutter picker once wired up
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map picker coming soon')),
    );
  }

  Future<void> _saveChanges() async {
    // TODO once Firebase is connected:
    // Update Firestore 'reports/{reportId}' with edited fields
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved (placeholder — Firebase pending)')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _deleteReport() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteConfirmationModal(
        title: 'Delete this report?',
        message: 'This action cannot be undone. This report will be '
            'permanently removed.',
      ),
    );

    if (confirmed == true) {
      // TODO once Firebase is connected:
      // Delete document from Firestore 'reports/{reportId}'
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted (placeholder — Firebase pending)')),
      );
      Navigator.of(context).pop();
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Report', style: AppTextStyles.heading2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header status strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusFound.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.statusFound),
                  const SizedBox(width: 8),
                  Text(
                    'Case #PB-4028 · Live Case',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.statusFound,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All details editable in-place · Changes instantly sync '
              'across community alerts',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 18),

            // Pet Photographs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pet Photographs *', style: AppTextStyles.heading2),
                Text('$photoCount of ${photoCount + 1} uploaded', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: AppColors.accentPeach.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.pets, size: 42, color: AppColors.primary),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Primary Portrait',
                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _changePhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.textPrimary),
                          SizedBox(width: 4),
                          Text('Change Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentPeach.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pets, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addMorePhotos,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Add more photos (+2)', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 22),

            // Report Type / Status
            Text('Report Type / Status *', style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: reportTypes.map((type) {
                final bool selected = selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedType = type),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.cardBackground,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Pet Name
            Text('Pet Name', style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            AppTextField(
              hintText: 'Pet name',
              icon: Icons.pets_outlined,
              controller: nameController,
            ),
            const SizedBox(height: 18),

            // Species, Breed & Vital Status
            Text('Species, Breed & Vital Status', style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            AppTextField(
              hintText: 'Species, breed and vital status',
              icon: Icons.info_outline,
              controller: speciesController,
            ),
            const SizedBox(height: 18),

            // Last Seen Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last Seen Location *', style: AppTextStyles.heading2),
                Row(
                  children: const [
                    Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('GPS locked', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppTextField(
              hintText: 'Location',
              icon: Icons.location_on_outlined,
              controller: locationController,
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    // TODO: replace with google_maps_flutter view
                    child: Icon(Icons.map_outlined, size: 32, color: AppColors.textSecondary),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _adjustPin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPeach,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Adjust pin',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Description
            Text('Pet Description & Distinct Marks', style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${descriptionController.text.length} / 500',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 18),

            // Special Care / Medical Alert
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusInjured.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, color: AppColors.statusInjured),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Special Care & Medical Alert',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Needs daily meds (Carinsulin) · Visible on public emergency card',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      // TODO: open a medical alert edit field
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            PrimaryButton(label: 'Save Changes', onPressed: _saveChanges),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _deleteReport,
                child: const Text(
                  'Delete Report',
                  style: TextStyle(color: AppColors.statusLost, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}