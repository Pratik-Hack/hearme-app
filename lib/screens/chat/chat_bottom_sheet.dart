import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/providers/coins_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/chat_service.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

void showChatBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ChatBottomSheet(),
  );
}

class _ChatBottomSheet extends StatefulWidget {
  const _ChatBottomSheet();

  @override
  State<_ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<_ChatBottomSheet> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _sessionId = '';
  String? _medicalContext;

  @override
  void initState() {
    super.initState();
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add({
      'role': 'bot',
      'content':
          "Hello! I'm your HearMe medical assistant. I can help you understand your symptoms, provide general health guidance, and advise when to see a doctor. How can I help you today?",
    });
    _loadMedicalSummary();
  }

  Future<void> _loadMedicalSummary() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        ApiService.setToken(auth.token);
        final response =
            await ApiService.get(ApiConstants.patientMedicalSummary);
        if (response['summary'] != null) {
          _medicalContext = response['summary'].toString();
        }
      }
    } catch (_) {
      // Medical summary is optional
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
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

    final lang =
        Provider.of<LocaleProvider>(context, listen: false).languageCode;

    try {
      String response = '';
      _messages.add({'role': 'bot', 'content': ''});

      await for (final token in ChatService.sendMessageStream(
        text,
        sessionId: _sessionId,
        language: lang,
        medicalContext: _medicalContext,
      )) {
        response += token;
        setState(() {
          _messages.last['content'] = response;
        });
        _scrollToBottom();
      }

      setState(() => _isTyping = false);

      final coins = Provider.of<CoinsProvider>(context, listen: false);
      await coins.addChatCoins();
    } catch (e) {
      setState(() {
        _isTyping = false;
        if (_messages.last['content'] == '') {
          _messages.last['content'] =
              'Sorry, something went wrong. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : AppTheme.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                      ),
                      child: const Icon(Icons.smart_toy_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HearMe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextLight
                                : AppTheme.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4ECDC4),
                              ),
                            ),
                            const SizedBox(width: 4),
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
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppTheme.darkTextGray
                            : AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isBot = message['role'] == 'bot';
                    return _buildMessage(message, isBot, isDark, index);
                  },
                ),
              ),

              // Typing indicator
              if (_isTyping && _messages.last['content'] == '')
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                  ),
                  child: _buildTypingIndicator(isDark),
                ),

              // Input
              _buildInput(isDark, lang),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessage(
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: isBot
                ? GlassCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textDark,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message['content'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
            ),
          ),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.textLight,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(delay: Duration(milliseconds: i * 200))
                  .then()
                  .fadeOut(delay: 400.ms),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(bool isDark, String lang) {
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
