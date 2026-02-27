import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppTheme.darkCard
              : Colors.white.withValues(alpha: 0.8),
          border: Border.all(
            color: AppTheme.primaryOrange.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: child,
            );
          },
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: AppTheme.primaryOrange,
            size: 20,
          ),
        ),
      ),
    );
  }
}
