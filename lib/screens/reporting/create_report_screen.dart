import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'duplicate_warning_modal.dart';
import '../../widgets/app_text_field.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  String? selectedCategory; // Lost, Found, Injured, Abandoned
  bool photoAttached = false; // placeholder flag until Storage is wired up

  // Location — stubbed with a fixed placeholder until map picker is wired up
  String locationLabel = 'Nugegoda Junction';
  String locationAccuracy = 'GPS pin dropped · ±20 m accuracy';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<String> categories = ['Lost', 'Found', 'Injured', 'Abandoned'];

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _adjustPin() {
    // TODO: open google_maps_flutter picker once wired up.
    // For now, this is a visual placeholder action only.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map picker coming soon')),
    );
  }

  Future<void> _onContinue() async {
    if (selectedCategory == null || !photoAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo and select a category.'),
          backgroundColor: AppColors.statusLost,
        ),
      );
      return;
    }

    // Duplicate check — stubbed for now, will query Firestore once connected
    final bool? isDuplicate = await showDialog<bool>(
      context: context,
      builder: (context) => const DuplicateWarningModal(
        existingReportSummary: 'A report matching this animal was submitted '
            '0.2 km away 40 minutes ago.',
      ),
    );

    // isDuplicate == true  -> same animal confirmed, cancel new report
    // isDuplicate == false -> different animal confirmed, proceed
    // isDuplicate == null  -> dismissed without choice, treat as cancel
    if (isDuplicate == null || isDuplicate == true) {
      return;
    }

    // TODO once Firebase is connected:
    // 1. Upload photo to Firebase Storage -> get photoUrl
    // 2. Create ReportModel with form data (category, location, description)
    // 3. Write to Firestore 'reports' collection
    // 4. Navigate to confirmation / back to Home

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted (placeholder — Firebase pending)')),
    );
    Navigator.of(context).pop();
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
        title: const Text('Report a Pet', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar — decorative, matches the high-fidelity screen
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
            const Text('Step 1 of 3 · Photo & Category', style: AppTextStyles.caption),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo upload box
                    GestureDetector(
                      onTap: () {
                        // Placeholder until image_picker + Storage is wired up
                        setState(() => photoAttached = true);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.accentPeach.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.accentPeach,
                                child: Icon(
                                  photoAttached ? Icons.check : Icons.camera_alt_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                photoAttached ? 'Photo added' : 'Add a clear photo',
                                style: AppTextStyles.heading2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A photo helps owners identify the pet fast',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category selector
                    Text('What are you reporting?', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((cat) {
                        final bool selected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => setState(() => selectedCategory = cat),
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
                    const SizedBox(height: 24),

                    // Pet Name (optional)
                    Text('Pet Name (optional)', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    AppTextField(
                      hintText: "Pet's name, if known",
                      icon: Icons.pets_outlined,
                      controller: nameController,
                    ),

                    // Location card
                    Text('Where was it seen?', style: AppTextStyles.heading2),
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
                              color: AppColors.accentPeach.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(locationLabel, style: AppTextStyles.bodyText.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                                const SizedBox(height: 2),
                                Text(locationAccuracy, style: AppTextStyles.caption),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _adjustPin,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6,
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

                    // Description
                    Text('Description (optional)', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Colour, collar, behaviour, distinctive marks...',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            PrimaryButton(label: 'Continue', onPressed: _onContinue),
          ],
        ),
      ),
    );
  }
}