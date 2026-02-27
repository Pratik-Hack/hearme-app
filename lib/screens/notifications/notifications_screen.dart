import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/vitals_service.dart';
import 'package:hearme/services/mental_health_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _vitalsAlerts = [];
  List<dynamic> _mentalHealthNotifs = [];
  bool _loadingVitals = true;
  bool _loadingMental = true;
  final Set<int> _expandedVitals = {};
  final Set<int> _expandedMental = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = auth.user?.id ?? '';

    // Load both in parallel
    _loadVitals(doctorId);
    _loadMentalHealth(doctorId);
  }

  Future<void> _loadVitals(String doctorId) async {
    try {
      final alerts = await VitalsService.getDoctorAlerts(doctorId);
      setState(() {
        _vitalsAlerts = alerts;
        _loadingVitals = false;
      });
    } catch (_) {
      setState(() => _loadingVitals = false);
    }
  }

  Future<void> _loadMentalHealth(String doctorId) async {
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF1744);
      case 'high':
        return const Color(0xFFFF5252);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF4CAF50);
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

    final unreadVitals =
        _vitalsAlerts.where((a) => a['read'] != true).length;

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryOrange,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextGray : AppTheme.textGray,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.get('vitals', lang)),
                  if (unreadVitals > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadVitals',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: AppStrings.get('mental_health', lang)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildVitalsTab(isDark, lang),
            _buildMentalHealthTab(isDark, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsTab(bool isDark, String lang) {
    if (_loadingVitals) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryOrange,
      child: _vitalsAlerts.isEmpty
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
              itemCount: _vitalsAlerts.length,
              itemBuilder: (context, index) {
                final alert = _vitalsAlerts[index];
                final isExpanded = _expandedVitals.contains(index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedVitals.remove(index);
                        } else {
                          _expandedVitals.add(index);
                        }
                      });
                      if (alert['id'] != null && alert['read'] != true) {
                        VitalsService.markAlertRead(alert['id']);
                        setState(() => alert['read'] = true);
                      }
                    },
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (alert['read'] != true)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF5252),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  'Patient: ${alert['patient_name'] ?? 'Unknown'}',
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
                                  color: _getSeverityColor(
                                          alert['severity'] ?? 'low')
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (alert['severity'] ?? 'Low').toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _getSeverityColor(
                                        alert['severity'] ?? 'low'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(alert['vital_type'] ?? '').toString().replaceAll('_', ' ')} — ${alert['message'] ?? ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextGray
                                  : AppTheme.textGray,
                            ),
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                          ),
                          if (isExpanded && alert['latitude'] != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                final url =
                                    'https://www.google.com/maps?q=${alert['latitude']},${alert['longitude']}';
                                launchUrl(Uri.parse(url));
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      color: AppTheme.primaryOrange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Patient Location',
                                    style: TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
              },
            ),
    );
  }

  Widget _buildMentalHealthTab(bool isDark, String lang) {
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
                      if (notif['id'] != null && notif['read'] != true) {
                        MentalHealthService.markAsRead(notif['id']);
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
                                  notif['patient_name'] ?? 'Patient',
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
