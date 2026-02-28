import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/screens/notifications/notifications_screen.dart';
import 'package:hearme/screens/linking/my_code_screen.dart';
import 'package:hearme/screens/welcome/welcome_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, isDark, lang, auth),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Builder(
                      builder: (ctx) => GestureDetector(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (auth.user?.name ?? 'D')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.get('hello', lang)},',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.darkTextGray
                                  : AppTheme.textGray,
                            ),
                          ),
                          Text(
                            'Dr. ${auth.user?.name ?? 'Doctor'}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextLight
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: AppTheme.spacingXXLarge),

                // Navigation tiles
                _buildTile(
                  context: context,
                  title: AppStrings.get('patient_notifications', lang),
                  subtitle: 'View mental health reports',
                  icon: Icons.notifications_active_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: AppTheme.spacingMedium),

                _buildTile(
                  context: context,
                  title: AppStrings.get('my_code', lang),
                  subtitle: auth.user?.uniqueCode ?? 'HM-XXXX',
                  icon: Icons.qr_code_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCodeScreen()),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextLight
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextGray
                          : AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, bool isDark, String lang, AuthProvider auth) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingLarge),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              child: Center(
                child: Text(
                  (auth.user?.name ?? 'D')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dr. ${auth.user?.name ?? 'Doctor'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
              ),
            ),
            Text(
              auth.user?.email ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            const Divider(),

            ListTile(
              leading: Icon(
                Icons.language_rounded,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
              title: Text(
                AppStrings.get('language', lang),
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
              trailing: DropdownButton<String>(
                value: lang,
                underline: const SizedBox.shrink(),
                dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  fontSize: 14,
                ),
                items: LocaleProvider.supportedLanguages.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (code) {
                  if (code != null) localeProvider.setLanguage(code);
                },
              ),
            ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text(
                AppStrings.get('logout', lang),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingMedium),
          ],
        ),
      ),
    );
  }
}
