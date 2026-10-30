import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    // Thời gian hiển thị splash screen tối thiểu để người dùng trải nghiệm hiệu ứng mượt mà
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900 Luxury Dark
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withAlpha(50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with luxury shadow and spring animation
                Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withAlpha(40),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withAlpha(60),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 56,
                        color: Colors.white,
                      );
                    },
                  ),
                )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                    )
                    .fadeIn(duration: 600.ms)
                    .shimmer(
                      delay: 900.ms,
                      duration: 1200.ms,
                      color: Colors.white.withAlpha(80),
                    ),

                const SizedBox(height: 32),

                // App Title
                Text(
                  'SMART WORKFLOW',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Adaptive Todo & Productivity Engine',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8), // Slate 400
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              ],
            ),
          ),

          // Bottom Loading Spinner
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withAlpha(160),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
