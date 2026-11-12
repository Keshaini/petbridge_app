
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _userType;

  static const List<Map<String, dynamic>> _userTypes = [
    {
      'value': 'owner',
      'title': 'Pet owner',
      'subtitle': 'I lost a pet or want to protect mine',
      'icon': Icons.pets,
    },
    {
      'value': 'finder',
      'title': 'Finder / community member',
      'subtitle': 'I found or saw a stray or injured animal',
      'icon': Icons.visibility_outlined,
    },
    {
      'value': 'shelter',
      'title': 'Shelter / rescue organisation',
      'subtitle': 'I respond to and manage cases',
      'icon': Icons.home_work_outlined,
    },
    {
      'value': 'vet',
      'title': 'Veterinary clinic',
      'subtitle': 'I treat and verify found animals',
      'icon': Icons.medical_services_outlined,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (_userType == null) {
      _showMessage('Please choose what best describes you.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.signUp(
        name: name,
        email: email,
        phone: '',
        password: password,
        userType: _userType!,
      );

      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignUp() async {
    if (_userType == null) {
      _showMessage('Please choose your account type first.');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await AuthService.signInWithGoogle(
        userType: _userType!,
      );

      if (!mounted) return;

      if (result == null) {
        _showMessage('Google sign-in was cancelled.');
        return;
      }

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5C3A21)),
      filled: true,
      fillColor: const Color(0xFFF5EBE1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _userTypeCard(Map<String, dynamic> type) {
    final bool selected = _userType == type['value'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _loading
            ? null
            : () => setState(
                  () => _userType = type['value'] as String,
                ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFDE1CC)
                : const Color(0xFFF5EBE1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF5C3A21)
                  : const Color(0xFFEEDCCF),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                type['icon'] as IconData,
                color: const Color(0xFF5C3A21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF3D2314),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A6B5D),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF5C3A21),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5C3A21)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account 🐾',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2314),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the PetBridge community to help reunite pets.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7A6B5D),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'I am a...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D2314),
                ),
              ),
              const SizedBox(height: 10),

              ..._userTypes.map(_userTypeCard),

              const SizedBox(height: 14),

              TextField(
                controller: _nameController,
                enabled: !_loading,
                decoration: _decoration(
                  _userType == 'shelter' || _userType == 'vet'
                      ? 'Organisation / clinic name'
                      : 'Full Name',
                  Icons.person_outline,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  'Email Address',
                  Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                enabled: !_loading,
                obscureText: true,
                decoration: _decoration(
                  'Password',
                  Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C3A21),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE4D5C8))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Color(0xFF7A6B5D)),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE4D5C8))),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _googleSignUp,
                  icon: Image.asset(
                    'assets/images/google-logo-png.webp',
                    width: 22,
                    height: 22,
                  ),
                  label: const Text(
                    'Sign up with Google',
                    style: TextStyle(
                      color: Color(0xFF3D2314),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE4D5C8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Color(0xFF7A6B5D)),
                  ),
                  GestureDetector(
                    onTap: _loading ? null : () => context.go('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF5C3A21),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
