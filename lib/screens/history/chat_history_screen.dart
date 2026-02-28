import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final data = await ApiService.get(ApiConstants.historyChats);
      setState(() {
        _sessions = data['sessions'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteSession(String id, int index) async {
    try {
      await ApiService.delete('${ApiConstants.historyChats}/$id');
      setState(() => _sessions.removeAt(index));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _confirmDelete(String id, int index, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSession(id, index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat History',
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
                onRefresh: _loadSessions,
                color: AppTheme.primaryOrange,
                child: _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: isDark
                                  ? AppTheme.darkTextDim
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chat history yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppTheme.darkTextGray
                                    : AppTheme.textGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your conversations will appear here',
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
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final id =
                              session['_id'] ?? session['id'] ?? '';
                          final title = session['title'] ?? 'Chat';
                          final messages =
                              session['messages'] as List<dynamic>? ?? [];
                          final messageCount = messages.length;
                          final date = session['updatedAt'] != null
                              ? DateTime.tryParse(session['updatedAt'])
                              : session['createdAt'] != null
                                  ? DateTime.tryParse(session['createdAt'])
                                  : null;
                          final dateStr = date != null
                              ? '${date.day}/${date.month}/${date.year}'
                              : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => _openChat(session, isDark),
                              child: GlassCard(
                                padding: const EdgeInsets.all(
                                    AppTheme.spacingMedium),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4ECDC4)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.smart_toy_rounded,
                                        color: Color(0xFF4ECDC4),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.darkTextLight
                                                  : AppTheme.textDark,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
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
                                    IconButton(
                                      onPressed: () => _confirmDelete(
                                          id, index, title),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: isDark
                                            ? AppTheme.darkTextDim
                                            : AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                              delay:
                                  Duration(milliseconds: 50 * index));
                        },
                      ),
              ),
      ),
    );
  }

  void _openChat(dynamic session, bool isDark) {
    final messages = session['messages'] as List<dynamic>? ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatDetailScreen(
          title: session['title'] ?? 'Chat',
          messages: messages,
        ),
      ),
    );
  }
}

class _ChatDetailScreen extends StatelessWidget {
  final String title;
  final List<dynamic> messages;

  const _ChatDetailScreen({
    required this.title,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
            fontSize: 16,
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
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                      ),
                      child: const Icon(Icons.smart_toy_rounded,
                          color: Colors.white, size: 15),
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
                                  Color(0xFF44A08D)
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
