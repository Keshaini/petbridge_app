import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../services/firestore_service.dart';
import '../../models/report_model.dart';
import 'delete_confirmation_modal.dart';

class EditReportScreen extends StatefulWidget {
  final String reportId;

  const EditReportScreen({super.key, required this.reportId});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  ReportModel? report;
  bool isLoading = true;
  bool isSaving = false;

  String? selectedType;
  final List<String> reportTypes = ['Lost', 'Found', 'Injured', 'Stray', 'Abandoned'];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController speciesController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool hasMedicalAlert = false;
  int photoCount = 1;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final fetched = await FirestoreService.getReport(widget.reportId);
    if (!mounted) return;

    if (fetched != null) {
      setState(() {
        report = fetched;
        selectedType = fetched.category;
        descriptionController.text = fetched.description;
        locationController.text = 'Nugegoda Junction'; // placeholder until map picker is wired up
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    speciesController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _changePhoto() {
    // TODO: open image_picker, upload to Cloudinary once connected here too
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo picker coming soon')),
    );
  }

  void _addMorePhotos() {
    setState(() => photoCount += 1);
  }

  void _adjustPin() {
    // TODO: open google_maps_flutter picker once wired up
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map picker coming soon')),
    );
  }

  Future<void> _saveChanges() async {
    if (report == null) return;
    setState(() => isSaving = true);

    try {
      await FirestoreService.updateReport(widget.reportId, {
        'category': selectedType ?? report!.category,
        'description': descriptionController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
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
      try {
        await FirestoreService.deleteReport(widget.reportId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (report == null) {
      return const Scaffold(
        body: Center(child: Text('Report not found')),
      );
    }

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
                    'Case #${widget.reportId.substring(0, widget.reportId.length > 6 ? 6 : widget.reportId.length)} · ${report!.status}',
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
                  child: report!.photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            report!.photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 170,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.pets, size: 42, color: AppColors.primary),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.pets, size: 42, color: AppColors.primary),
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
                const Text('Add more photos', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 22),

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

            Text('Pet Name', style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            AppTextField(
              hintText: 'Pet name',
              icon: Icons.pets_outlined,
              controller: nameController,
            ),
            const SizedBox(height: 18),

            Text('Species, Breed & Vital Status', style: AppTextStyles.heading2),
            const SizedBox(height: 10),
            AppTextField(
              hintText: 'Species, breed and vital status',
              icon: Icons.info_outline,
              controller: speciesController,
            ),
            const SizedBox(height: 18),

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
            const SizedBox(height: 24),

            PrimaryButton(
              label: isSaving ? 'Saving...' : 'Save Changes',
              onPressed: isSaving ? () {} : _saveChanges,
            ),
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