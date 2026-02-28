import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/mental_health_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _mentalHealthNotifs = [];
  bool _loadingMental = true;
  final Set<int> _expandedMental = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = auth.user?.id ?? '';
    try {
      final notifs = await MentalHealthService.getNotifications(doctorId);
      setState(() {
        _mentalHealthNotifs = notifs;
        _loadingMental = false;
      });
    } catch (_) {
      setState(() => _loadingMental = false);
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF5252);
      case 'moderate':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('notifications', lang),
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
        child: _buildMentalHealthList(isDark, lang),
      ),
    );
  }

  Widget _buildMentalHealthList(bool isDark, String lang) {
    if (_loadingMental) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryOrange,
      child: _mentalHealthNotifs.isEmpty
          ? Center(
              child: Text(
                AppStrings.get('no_notifications', lang),
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              itemCount: _mentalHealthNotifs.length,
              itemBuilder: (context, index) {
                final notif = _mentalHealthNotifs[index];
                final isExpanded = _expandedMental.contains(index);
                final urgency = notif['urgency'] ?? 'low';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedMental.remove(index);
                        } else {
                          _expandedMental.add(index);
                        }
                      });
                      final notifId = notif['_id'] ?? notif['id'];
                      if (notifId != null && notif['read'] != true) {
                        MentalHealthService.markAsRead(notifId);
                        setState(() => notif['read'] = true);
                      }
                    },
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C4DFF),
                                      Color(0xFF536DFE),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  notif['patientName'] ?? notif['patient_name'] ?? 'Patient',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkTextLight
                                        : AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getUrgencyColor(urgency)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  urgency.toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _getUrgencyColor(urgency),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notif['clinicalReport'] ??
                                notif['clinical_report'] ??
                                notif['summary'] ??
                                'Mental health check-in',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextGray
                                  : AppTheme.textGray,
                              height: 1.5,
                            ),
                            maxLines: isExpanded ? null : 3,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
              },
            ),
    );
  }
}
