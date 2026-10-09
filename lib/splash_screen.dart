import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for 3 seconds, then automatically go to Onboarding
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5EBE1),
                  border: Border.all(
                    color: const Color(0xFFEEDCCF),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pets,
                        size: 64,
                        color: Color(0xFF5C3A21),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE38B75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '♥',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'PetBridge',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2314),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.pets,
                    color: Color(0xFF5C3A21),
                    size: 28,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Text(
                'Reuniting pets and families, together.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A6B5D),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 14,
                    color: Color(0xFF5C3A21),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'v1.0  •  Made with love for pets',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E8B7C),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Shelter network online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A6B5D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}