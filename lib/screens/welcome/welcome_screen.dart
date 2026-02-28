import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/animated_button.dart';
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/screens/auth/role_selection_screen.dart';
import 'package:hearme/screens/dashboard/patient_dashboard_screen.dart';
import 'package:hearme/screens/dashboard/doctor_dashboard_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => auth.isDoctor
                ? const DoctorDashboardScreen()
                : const PatientDashboardScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Theme toggle
                  Align(
                    alignment: Alignment.topRight,
                    child: const ThemeToggleButton(),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: AppTheme.spacingXXLarge),

                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.orangeGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // App name
                  Text(
                    AppStrings.get('app_name', lang),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                  const SizedBox(height: AppTheme.spacingSmall),

                  // Tagline
                  Text(
                    AppStrings.get('your_mental_health_companion', lang),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Description
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                    child: Text(
                      AppStrings.get('welcome_description', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                        height: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: AppTheme.spacingXXLarge),

                  // Features row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureChip(Icons.smart_toy_rounded, 'AI Chat', isDark),
                      _buildFeatureChip(Icons.mic_rounded, 'Mind Space', isDark),
                      _buildFeatureChip(Icons.link_rounded, 'Connect', isDark),
                    ],
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                  const SizedBox(height: AppTheme.spacingXXLarge),

                  // Get Started button
                  AnimatedButton(
                    text: AppStrings.get('get_started', lang),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoleSelectionScreen(),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),

                  const SizedBox(height: AppTheme.spacingLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppTheme.darkCard
                : Colors.white.withValues(alpha: 0.8),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryOrange,
            size: 26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}
