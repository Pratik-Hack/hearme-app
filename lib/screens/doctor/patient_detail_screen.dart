import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/services/mental_health_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _alerts = [];
  List<dynamic> _mindspace = [];
  List<dynamic> _chats = [];
  bool _loadingAlerts = true;
  bool _loadingMindspace = true;
  bool _loadingChats = true;
  final Set<int> _expandedAlerts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadAlerts();
    _loadMindspace();
    _loadChats();
  }

  Future<void> _loadAlerts() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = auth.user?.id ?? '';
      final allNotifs = await MentalHealthService.getNotifications(doctorId);
      // Filter notifications for this patient
      final patientNotifs = allNotifs
          .where((n) => n['patient_id'] == widget.patientId)
          .toList();
      setState(() {
        _alerts = patientNotifs;
        _loadingAlerts = false;
      });
    } catch (_) {
      setState(() => _loadingAlerts = false);
    }
  }

  Future<void> _loadMindspace() async {
    try {
      final data = await ApiService.get(
        ApiConstants.doctorPatientMindspace(widget.patientId),
      );
      setState(() {
        _mindspace = data['records'] ?? [];
        _loadingMindspace = false;
      });
    } catch (_) {
      setState(() => _loadingMindspace = false);
    }
  }

  Future<void> _loadChats() async {
    try {
      final data = await ApiService.get(
        ApiConstants.doctorPatientChats(widget.patientId),
      );
      setState(() {
        _chats = data['sessions'] ?? [];
        _loadingChats = false;
      });
    } catch (_) {
      setState(() => _loadingChats = false);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName,
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
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextGray : AppTheme.textGray,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active_rounded, size: 20), text: 'Alerts'),
            Tab(icon: Icon(Icons.psychology_rounded, size: 20), text: 'MindSpace'),
            Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 20), text: 'Chats'),
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
            _buildAlertsTab(isDark),
            _buildMindspaceTab(isDark),
            _buildChatsTab(isDark),
          ],
        ),
      ),
    );
  }

  // ── Alerts Tab ──────────────────────────────────────────────────────────────

  Widget _buildAlertsTab(bool isDark) {
    if (_loadingAlerts) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 56, color: isDark ? AppTheme.darkTextDim : AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No alerts for this patient',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final isExpanded = _expandedAlerts.contains(index);
          final urgency = alert['urgency'] ?? 'low';
          final timestamp = alert['timestamp'];
          String dateStr = '';
          if (timestamp != null) {
            final date = DateTime.tryParse(timestamp);
            if (date != null) {
              dateStr = '${date.day}/${date.month}/${date.year}';
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedAlerts.remove(index);
                  } else {
                    _expandedAlerts.add(index);
                  }
                });
                if (alert['id'] != null && alert['read'] != true) {
                  MentalHealthService.markAsRead(alert['id']);
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(urgency)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            urgency.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _getUrgencyColor(urgency),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextDim
                                : AppTheme.textLight,
                          ),
                        ),
                        const Spacer(),
                        if (alert['read'] != true)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF5252),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      alert['clinical_report'] ??
                          alert['summary'] ??
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
                    if (isExpanded && alert['transcript'] != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient\'s Words:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextDim
                                    : AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['transcript'],
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppTheme.darkTextDim
                                    : AppTheme.textLight,
                                height: 1.4,
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

  // ── MindSpace Tab ───────────────────────────────────────────────────────────

  Widget _buildMindspaceTab(bool isDark) {
    if (_loadingMindspace) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_mindspace.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined,
                size: 56, color: isDark ? AppTheme.darkTextDim : AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No MindSpace records yet',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMindspace,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: _mindspace.length,
        itemBuilder: (context, index) {
          final record = _mindspace[index];
          final response = record['response'] ?? '';
          final transcript = record['transcript'] ?? '';
          final urgency = record['urgency'] ?? 'low';
          final date = record['createdAt'] != null
              ? DateTime.tryParse(record['createdAt'])
              : null;
          final dateStr =
              date != null ? '${date.day}/${date.month}/${date.year}' : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                          color:
                              const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            color: Color(0xFF7C4DFF), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 14,
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
                          urgency.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getUrgencyColor(urgency),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    response,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                  if (transcript.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '"$transcript"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppTheme.darkTextDim
                              : AppTheme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
        },
      ),
    );
  }

  // ── Chats Tab ───────────────────────────────────────────────────────────────

  Widget _buildChatsTab(bool isDark) {
    if (_loadingChats) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: isDark ? AppTheme.darkTextDim : AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No chat history yet',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final session = _chats[index];
          final title = session['title'] ?? 'Chat';
          final messages = session['messages'] as List<dynamic>? ?? [];
          final messageCount = messages.length;
          final date = session['updatedAt'] != null
              ? DateTime.tryParse(session['updatedAt'])
              : session['createdAt'] != null
                  ? DateTime.tryParse(session['createdAt'])
                  : null;
          final dateStr =
              date != null ? '${date.day}/${date.month}/${date.year}' : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _openChatDetail(session, isDark),
              child: GlassCard(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.smart_toy_rounded,
                          color: Color(0xFF4ECDC4), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextLight
                                  : AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$messageCount messages  •  $dateStr',
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
                      size: 14,
                      color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
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

  void _openChatDetail(dynamic session, bool isDark) {
    final messages = session['messages'] as List<dynamic>? ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatViewScreen(
          title: session['title'] ?? 'Chat',
          patientName: widget.patientName,
          messages: messages,
        ),
      ),
    );
  }
}

// ── Read-only Chat View ─────────────────────────────────────────────────────

class _ChatViewScreen extends StatelessWidget {
  final String title;
  final String patientName;
  final List<dynamic> messages;

  const _ChatViewScreen({
    required this.title,
    required this.patientName,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientName,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ],
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
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isBot = msg['role'] == 'bot';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment:
                    isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBot) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                      ),
                      child: const Icon(Icons.smart_toy_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isBot
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF4ECDC4),
                                  Color(0xFF44A08D),
                                ],
                              ),
                        color: isBot
                            ? (isDark
                                ? AppTheme.darkCard
                                : Colors.white.withValues(alpha: 0.8))
                            : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isBot ? 4 : 16),
                          bottomRight: Radius.circular(isBot ? 16 : 4),
                        ),
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: TextStyle(
                          color: isBot
                              ? (isDark
                                  ? AppTheme.darkTextLight
                                  : AppTheme.textDark)
                              : Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
