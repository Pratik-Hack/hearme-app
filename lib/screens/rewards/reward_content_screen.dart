import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';

class RewardContentScreen extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const RewardContentScreen({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

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
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor:
                  isDark ? AppTheme.darkBackground : AppTheme.background,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Icon(icon, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._parseContent(content, isDark),
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // AI disclaimer
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkCard.withValues(alpha: 0.5)
                            : Colors.orange.withValues(alpha: 0.05),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.primaryOrange,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.get('ai_disclaimer', lang),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextGray
                                    : AppTheme.textGray,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseContent(String text, bool isDark) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    int delay = 100;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (trimmed.startsWith('# ') || trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
        final headerText = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: delay)),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('• ') || trimmed.startsWith('* ')) {
        final bulletText = trimmed.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bulletText,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark
                          ? AppTheme.darkTextGray
                          : AppTheme.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: delay)),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              trimmed,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: delay)),
        );
      }

      delay += 50;
    }

    return widgets;
  }
}
