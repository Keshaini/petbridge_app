import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  String? _photoUrl;

  static const Color _backgroundColor = Color(0xFFFFF4EF);
  static const Color _brown = Color(0xFF8A4B2D);
  static const Color _textColor = Color(0xFF2C2420);
  static const Color _mutedColor = Color(0xFF8E8178);
  static const Color _peachColor = Color(0xFFFCEAE0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD EXISTING PROFILE (READ)
  // ---------------------------------------------------------------------------

  Future<void> _loadProfile() async {
    try {
      final uid = AuthService.currentUid;
      _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';

      if (uid == 'guest') {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('Please log in to edit your profile.');
        }
        return;
      }

      final document =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!mounted) return;

      if (document.exists) {
        final data = document.data() ?? {};

        _nameController.text = data['name']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _locationController.text = data['location']?.toString() ?? '';
        _photoUrl = data['photoUrl']?.toString();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Unable to load your profile. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // CHANGE PHOTO (uploads to Cloudinary, saved with the profile)
  // ---------------------------------------------------------------------------

  Future<void> _changePhoto() async {
    if (_isUploadingPhoto) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    final url = await CloudinaryService.uploadImage(picked);

    if (!mounted) return;

    setState(() {
      _isUploadingPhoto = false;
      if (url != null) _photoUrl = url;
    });

    _showMessage(
      url != null
          ? 'Photo updated. Tap Save Changes to keep it.'
          : 'Photo upload failed. Please try again.',
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE PROFILE (UPDATE)
  // ---------------------------------------------------------------------------

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final uid = AuthService.currentUid;

    if (uid == 'guest') {
      _showMessage('Please log in to save your profile.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        if (_photoUrl != null) 'photoUrl': _photoUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _brown,
        ),
      );

      _goBack();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showMessage('Could not save your profile. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _brown,
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _brown))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildPhotoSection(),
                      const SizedBox(height: 24),

                      _buildFieldLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must contain at least 2 characters.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          hint: 'Email address',
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel('Phone Number'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6F0E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'For rescue alerts',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hint: 'e.g. 0771234567',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null; // optional
                          final digits = text.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 7) {
                            return 'Please enter a valid phone number.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Neighborhood & City'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          hint: 'Enter your area and city',
                          icon: Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your location.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      _buildStatusCard(),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_isSaving || _isUploadingPhoto)
                              ? null
                              : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                            disabledBackgroundColor:
                                _brown.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.check_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER: back arrow, title, avatar badge
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: _goBack,
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: _textColor,
          ),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: _brown,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PHOTO WITH CAMERA BADGE + "Change photo"
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _changePhoto,
            child: Stack(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFF2C9AE),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _isUploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _brown,
                              strokeWidth: 2.5,
                            ),
                          )
                        : _buildProfileImage(),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _brown,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _changePhoto,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change photo',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _brown,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.edit_outlined, size: 13, color: _brown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
      return Image.network(
        _photoUrl!,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: _peachColor,
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, size: 56, color: _brown),
    );
  }

  // ---------------------------------------------------------------------------
  // VOLUNTEER & FOSTER STATUS CARD
  // ---------------------------------------------------------------------------

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _peachColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pets_rounded, color: _brown, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volunteer & Foster Status',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your volunteer status appears on your profile and is '
                  'visible to shelters you connect with.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED PIECES
  // ---------------------------------------------------------------------------

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: _textColor,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB2A49B)),
      prefixIcon: Icon(icon, color: _textColor, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brown, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }
}