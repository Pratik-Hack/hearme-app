import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/coins_provider.dart';
import 'package:hearme/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add({
      'role': 'bot',
      'content':
          "Hello! I'm your HearMe medical assistant. I can help you understand your symptoms, provide general health guidance, and advise when to see a doctor. How can I help you today?",
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _scrollToBottom();

    final lang = Provider.of<LocaleProvider>(context, listen: false).languageCode;

    try {
      final response = await ChatService.sendMessage(
        text,
        sessionId: _sessionId,
        language: lang,
      );

      setState(() {
        _messages.add({'role': 'bot', 'content': response});
        _isTyping = false;
      });
      _scrollToBottom();

      // Award chat coins
      if (!mounted) return;
      final coins = Provider.of<CoinsProvider>(context, listen: false);
      await coins.addChatCoins();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'content':
              'Sorry, I couldn\'t respond right now. The server may be starting up — please try again in a moment.',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HearMe',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                  ),
                ),
                Text(
                  AppStrings.get('online', lang),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return _buildTypingIndicator(isDark);
                  }
                  final message = _messages[index];
                  final isBot = message['role'] == 'bot';
                  return _buildMessageBubble(message, isBot, isDark, index);
                },
              ),
            ),
            _buildInputBar(isDark, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isBot, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot
                    ? (isDark ? AppTheme.darkCard : Colors.white)
                    : const Color(0xFF4ECDC4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBot ? 4 : 16),
                  bottomRight: Radius.circular(isBot ? 16 : 4),
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isBot
                      ? (isDark ? AppTheme.darkTextLight : AppTheme.textDark)
                      : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.textLight,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(),
                    )
                    .fadeIn(delay: Duration(milliseconds: i * 200))
                    .then()
                    .fadeOut(delay: 400.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.get('type_message', lang),
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
