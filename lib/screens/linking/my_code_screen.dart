import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';

class MyCodeScreen extends StatelessWidget {
  const MyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;
    final auth = Provider.of<AuthProvider>(context);
    final code = auth.user?.uniqueCode ?? 'HM-XXXX';
    final isDoctor = auth.isDoctor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('your_unique_code', lang),
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR icon placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.orangeGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: AppTheme.spacingXLarge),

                // Code display
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXLarge,
                    vertical: AppTheme.spacingLarge,
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.get('your_unique_code', lang),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextGray
                              : AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryOrange,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: AppTheme.spacingMedium),

                // Copy button
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.get('code_copied', lang)),
                        backgroundColor: AppTheme.primaryOrange,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryOrange,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded,
                            color: AppTheme.primaryOrange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.get('copy_code', lang),
                          style: TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: AppTheme.spacingXLarge),

                // Description
                Text(
                  AppStrings.get(
                    isDoctor ? 'share_code_doctor' : 'share_code_patient',
                    lang,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
