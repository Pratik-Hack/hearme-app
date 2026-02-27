import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/coins_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/mental_health_service.dart';
import 'package:hearme/screens/rewards/reward_content_screen.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;
    final coins = Provider.of<CoinsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('mind_rewards', lang),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coin display
              Center(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXLarge,
                    vertical: AppTheme.spacingLarge,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${coins.coins}',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textDark,
                        ),
                      ),
                      Text(
                        AppStrings.get('mind_coins', lang),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextGray
                              : AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: AppTheme.spacingMedium),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.get('streak', lang),
                      '${coins.currentStreak} ${AppStrings.get('days', lang)}',
                      Icons.local_fire_department_rounded,
                      const Color(0xFFFF6B35),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.get('best_streak', lang),
                      '${coins.bestStreak} ${AppStrings.get('days', lang)}',
                      Icons.emoji_events_rounded,
                      const Color(0xFFFFD700),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.get('sessions', lang),
                      '${coins.totalSessions}',
                      Icons.psychology_rounded,
                      const Color(0xFF7C4DFF),
                      isDark,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Ways to Earn
              Text(
                AppStrings.get('ways_to_earn', lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              _buildEarnItem(
                AppStrings.get('daily_checkin', lang),
                '+10',
                Icons.mic_rounded,
                const Color(0xFF7C4DFF),
                isDark,
              ).animate().fadeIn(delay: 350.ms),
              _buildEarnItem(
                AppStrings.get('streak_bonus_3', lang),
                '+15',
                Icons.local_fire_department_rounded,
                const Color(0xFFFF6B35),
                isDark,
              ).animate().fadeIn(delay: 400.ms),
              _buildEarnItem(
                AppStrings.get('streak_bonus_7', lang),
                '+50',
                Icons.emoji_events_rounded,
                const Color(0xFFFFD700),
                isDark,
              ).animate().fadeIn(delay: 450.ms),
              _buildEarnItem(
                AppStrings.get('chat_with_bot', lang),
                '+5/day',
                Icons.smart_toy_rounded,
                const Color(0xFF4ECDC4),
                isDark,
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Redeem Rewards
              Text(
                AppStrings.get('redeem_rewards', lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              _buildRedeemItem(
                context: context,
                title: AppStrings.get('guided_meditation', lang),
                cost: 30,
                icon: Icons.self_improvement_rounded,
                color: const Color(0xFF7C4DFF),
                rewardType: 'guided_meditation',
                isDark: isDark,
                lang: lang,
              ).animate().fadeIn(delay: 600.ms),
              _buildRedeemItem(
                context: context,
                title: AppStrings.get('weekly_wellness', lang),
                cost: 50,
                icon: Icons.assessment_rounded,
                color: const Color(0xFF4ECDC4),
                rewardType: 'weekly_wellness',
                isDark: isDark,
                lang: lang,
              ).animate().fadeIn(delay: 650.ms),
              _buildRedeemItem(
                context: context,
                title: AppStrings.get('premium_health_tips', lang),
                cost: 80,
                icon: Icons.lightbulb_rounded,
                color: const Color(0xFFFF6B35),
                rewardType: 'premium_health_tips',
                isDark: isDark,
                lang: lang,
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: AppTheme.spacingXLarge),

              // Motivational footer
              Center(
                child: Text(
                  'Keep taking care of yourself! Every check-in counts.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: AppTheme.spacingMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarnItem(
    String title,
    String coins,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                coins,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemItem({
    required BuildContext context,
    required String title,
    required int cost,
    required IconData icon,
    required Color color,
    required String rewardType,
    required bool isDark,
    required String lang,
  }) {
    final coinsProvider = Provider.of<CoinsProvider>(context);
    final canAfford = coinsProvider.coins >= cost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: canAfford
            ? () => _showRedeemDialog(
                  context, title, cost, icon, color, rewardType, isDark, lang)
            : null,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppTheme.primaryOrange
                      : (isDark ? AppTheme.darkCard : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: canAfford ? Colors.white : AppTheme.textLight,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cost',
                      style: TextStyle(
                        color: canAfford ? Colors.white : AppTheme.textLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(
    BuildContext context,
    String title,
    int cost,
    IconData icon,
    Color color,
    String rewardType,
    bool isDark,
    String lang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '${AppStrings.get('redeem', lang)} $title?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          ),
        ),
        content: Text(
          'This will cost $cost ${AppStrings.get('coins', lang)}.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _redeemReward(context, title, cost, icon, color, rewardType,
                  isDark, lang);
            },
            child: const Text(
              'Redeem',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(
    BuildContext context,
    String title,
    int cost,
    IconData icon,
    Color color,
    String rewardType,
    bool isDark,
    String lang,
  ) async {
    final coins = Provider.of<CoinsProvider>(context, listen: false);
    final success = await coins.spendCoins(cost);
    if (!success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('insufficient_coins', lang)),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryOrange),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('generating_content', lang),
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final result = await MentalHealthService.redeemReward(
        rewardType: rewardType,
        language: lang,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RewardContentScreen(
              title: title,
              content: result['content'] ?? 'Content generated.',
              icon: icon,
              color: color,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('something_went_wrong', lang)),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }
}
