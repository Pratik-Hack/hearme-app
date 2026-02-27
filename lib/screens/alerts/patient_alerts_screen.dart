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

class PatientAlertsScreen extends StatefulWidget {
  const PatientAlertsScreen({super.key});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final alerts = await VitalsService.getPatientAlerts(auth.user?.id ?? '');
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  IconData _getVitalIcon(String vitalType) {
    switch (vitalType.toLowerCase()) {
      case 'heart_rate':
        return Icons.favorite_rounded;
      case 'blood_pressure':
        return Icons.speed_rounded;
      case 'spo2':
        return Icons.air_rounded;
      case 'temperature':
        return Icons.thermostat_rounded;
      default:
        return Icons.monitor_heart_rounded;
    }
  }

  String _timeAgo(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    final criticalCount =
        _alerts.where((a) => (a['severity'] ?? '').toLowerCase() == 'critical').length;
    final sentToDoctor =
        _alerts.where((a) => a['doctor_notified'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('health_alerts', lang),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
            : RefreshIndicator(
                onRefresh: _loadAlerts,
                color: AppTheme.primaryOrange,
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  children: [
                    // Summary card
                    GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            AppStrings.get('total_alerts', lang),
                            '${_alerts.length}',
                            isDark,
                          ),
                          _buildStat(
                            AppStrings.get('critical_alerts', lang),
                            '$criticalCount',
                            isDark,
                            color: const Color(0xFFFF1744),
                          ),
                          _buildStat(
                            AppStrings.get('sent_to_doctor', lang),
                            '$sentToDoctor',
                            isDark,
                            color: const Color(0xFF4ECDC4),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: AppTheme.spacingMedium),

                    if (_alerts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingXXLarge),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 64,
                                color: isDark
                                    ? AppTheme.darkTextDim
                                    : AppTheme.textLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No alerts',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? AppTheme.darkTextGray
                                      : AppTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Alert cards
                    ...List.generate(_alerts.length, (index) {
                      final alert = _alerts[index];
                      final isExpanded = _expandedIndices.contains(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedIndices.remove(index);
                              } else {
                                _expandedIndices.add(index);
                              }
                            });
                            // Mark as read
                            if (alert['id'] != null && alert['read'] != true) {
                              VitalsService.markAlertRead(alert['id']);
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
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(
                                                alert['severity'] ?? 'low')
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getVitalIcon(
                                            alert['vital_type'] ?? ''),
                                        color: _getSeverityColor(
                                            alert['severity'] ?? 'low'),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (alert['vital_type'] ?? 'Unknown')
                                                .toString()
                                                .replaceAll('_', ' ')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.darkTextLight
                                                  : AppTheme.textDark,
                                            ),
                                          ),
                                          Text(
                                            _timeAgo(alert['timestamp']),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(
                                                alert['severity'] ?? 'low')
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (alert['severity'] ?? 'Low')
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: _getSeverityColor(
                                              alert['severity'] ?? 'low'),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: isDark
                                          ? AppTheme.darkTextDim
                                          : AppTheme.textLight,
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    'Current Value',
                                    alert['current_value']?.toString() ?? '-',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Predicted Value',
                                    alert['predicted_value']?.toString() ?? '-',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Message',
                                    alert['message']?.toString() ?? '-',
                                    isDark,
                                  ),
                                  if (alert['latitude'] != null &&
                                      alert['longitude'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          final url =
                                              'https://www.google.com/maps?q=${alert['latitude']},${alert['longitude']}';
                                          launchUrl(Uri.parse(url));
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              color: AppTheme.primaryOrange,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'View on Maps',
                                              style: TextStyle(
                                                color: AppTheme.primaryOrange,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (alert['doctor_notified'] == true)
                                        _buildStatusChip(
                                          Icons.check_circle_rounded,
                                          AppStrings.get(
                                              'alert_sent_doctor', lang),
                                          const Color(0xFF4ECDC4),
                                        ),
                                      if (alert['emergency_dispatched'] == true)
                                        _buildStatusChip(
                                          Icons.local_hospital_rounded,
                                          AppStrings.get(
                                              'alert_sent_emergency', lang),
                                          const Color(0xFFFF5252),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 100 * index));
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDark, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color ?? (isDark ? AppTheme.darkTextLight : AppTheme.textDark),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
