import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/screens/auth/registration_screen.dart';
import 'package:hearme/screens/auth/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
          child: Column(
            children: [
              // Header - pinned at top
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    const ThemeToggleButton(),
                  ],
                ),
              ),

              // Scrollable centered content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                // Title
                Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                const SizedBox(height: AppTheme.spacingSmall),

                Text(
                  'Select how you want to use HearMe',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: AppTheme.spacingXXLarge),

                // Patient card
                _buildRoleCard(
                  context: context,
                  role: 'patient',
                  title: AppStrings.get('patient', lang),
                  subtitle: 'Get AI health guidance, mental health support & connect with your doctor',
                  icon: Icons.person_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                const SizedBox(height: AppTheme.spacingMedium),

                // Doctor card
                _buildRoleCard(
                  context: context,
                  role: 'doctor',
                  title: AppStrings.get('doctor', lang),
                  subtitle: 'Monitor your patients\' mental health reports',
                  icon: Icons.medical_services_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.2),

                const SizedBox(height: AppTheme.spacingXXLarge),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.get('already_have_account', lang),
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextGray
                            : AppTheme.textGray,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.get('login', lang),
                        style: const TextStyle(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationScreen(role: role),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
