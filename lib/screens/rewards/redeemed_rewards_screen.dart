import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';
import 'package:hearme/screens/rewards/reward_content_screen.dart';

class RedeemedRewardsScreen extends StatefulWidget {
  const RedeemedRewardsScreen({super.key});

  @override
  State<RedeemedRewardsScreen> createState() => _RedeemedRewardsScreenState();
}

class _RedeemedRewardsScreenState extends State<RedeemedRewardsScreen> {
  List<dynamic> _rewards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final data = await ApiService.get(ApiConstants.rewardsRedeemed);
      setState(() {
        _rewards = data['rewards'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'guided_meditation':
        return Icons.self_improvement_rounded;
      case 'weekly_wellness':
        return Icons.assessment_rounded;
      case 'premium_health_tips':
        return Icons.lightbulb_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'guided_meditation':
        return const Color(0xFF7C4DFF);
      case 'weekly_wellness':
        return const Color(0xFF4ECDC4);
      case 'premium_health_tips':
        return const Color(0xFFFF6B35);
      default:
        return AppTheme.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Rewards',
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
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryOrange),
              )
            : RefreshIndicator(
                onRefresh: _loadRewards,
                color: AppTheme.primaryOrange,
                child: _rewards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.card_giftcard_rounded,
                              size: 64,
                              color: isDark
                                  ? AppTheme.darkTextDim
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No redeemed rewards yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppTheme.darkTextGray
                                    : AppTheme.textGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Redeem rewards from the Mind Rewards page',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextDim
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: _rewards.length,
                        itemBuilder: (context, index) {
                          final reward = _rewards[index];
                          final type = reward['rewardType'] ?? '';
                          final icon = _getIcon(type);
                          final color = _getColor(type);
                          final date = reward['redeemedAt'] != null
                              ? DateTime.tryParse(reward['redeemedAt'])
                              : null;
                          final dateStr = date != null
                              ? '${date.day}/${date.month}/${date.year}'
                              : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RewardContentScreen(
                                      title: reward['title'] ?? 'Reward',
                                      content: reward['content'] ?? '',
                                      icon: icon,
                                      color: color,
                                    ),
                                  ),
                                );
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.all(
                                    AppTheme.spacingMedium),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color:
                                            color.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child:
                                          Icon(icon, color: color, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reward['title'] ?? 'Reward',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.darkTextLight
                                                  : AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppTheme.darkTextDim
                                                  : AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: isDark
                                          ? AppTheme.darkTextDim
                                          : AppTheme.textLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                              delay: Duration(milliseconds: 50 * index));
                        },
                      ),
              ),
      ),
    );
  }
}
