import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/screens/welcome/welcome_screen.dart';
import 'package:hearme/screens/dashboard/patient_dashboard_screen.dart';
import 'package:hearme/screens/dashboard/doctor_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowAnimation;

  // Heart icon beat
  late Animation<double> _heartBeat;

  // Text animations
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Loading dot animation
  late Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Continuous pulse for the heart
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo: fade in + scale with gentle overshoot
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    // Glow grows around the logo
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );

    // Heart beat pulse (continuous after entrance)
    _heartBeat = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Title: fade + slide up
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline: fade + slide up (delayed)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Loading dots
    _dotsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Start heartbeat pulse after logo appears
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final results = await Future.wait([
      auth.tryRestoreSession(),
      Future.delayed(const Duration(milliseconds: 2800)),
    ]);

    final hasSession = results[0] as bool;

    if (!mounted) return;

    Widget destination;
    if (hasSession) {
      destination = auth.isDoctor
          ? const DoctorDashboardScreen()
          : const PatientDashboardScreen();
    } else {
      destination = const WelcomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_mainController, _pulseController]),
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo with glow + heartbeat
                _buildLogo(isDark),

                const SizedBox(height: 32),

                // App name
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      'HearMe',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Your Mental Health Companion',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryOrange.withValues(alpha: 0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Loading indicator
                FadeTransition(
                  opacity: _dotsAnimation,
                  child: _buildLoadingDots(isDark),
                ),

                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return FadeTransition(
      opacity: _logoFade,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.orangeGradient,
            boxShadow: [
              // Animated glow
              BoxShadow(
                color: AppTheme.primaryOrange
                    .withValues(alpha: 0.15 + (_glowAnimation.value * 0.3)),
                blurRadius: 20 + (_glowAnimation.value * 40),
                spreadRadius: _glowAnimation.value * 10,
              ),
              // Subtle depth shadow
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Transform.scale(
              scale: _heartBeat.value,
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 68,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        // Stagger each dot
        final delay = index * 0.15;
        final progress = (_mainController.value - 0.75 - delay)
            .clamp(0.0, 0.25) / 0.25;
        final bounce = sin(progress * pi * 2 +
            (_pulseController.value * pi * 2) +
            (index * pi * 0.6));
        final dotScale = 0.6 + (0.4 * ((bounce + 1) / 2));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: dotScale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange
                    .withValues(alpha: 0.4 + (0.5 * ((bounce + 1) / 2))),
              ),
            ),
          ),
        );
      }),
    );
  }
}
