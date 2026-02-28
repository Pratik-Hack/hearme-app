import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/providers/coins_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/mental_health_service.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class MentalHealthScreen extends StatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  State<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends State<MentalHealthScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _hasResult = false;
  int _countdown = 30;
  Timer? _timer;
  String? _response;
  int _coinsEarned = 0;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        ApiService.setToken(auth.token);
        final result = await ApiService.get(ApiConstants.patientDoctor);
        if (result['doctor'] != null) {
          _doctorId = result['doctor']['id'] ?? result['doctor']['_id'];
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/mental_health_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _countdown = 30;
        _hasResult = false;
        _response = null;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _countdown--);
        if (_countdown <= 0) {
          _stopRecording();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    if (path != null) {
      await _analyzeAudio(path);
    } else {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _analyzeAudio(String filePath) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final lang = Provider.of<LocaleProvider>(context, listen: false).languageCode;

      final result = await MentalHealthService.uploadAudio(
        filePath: filePath,
        patientId: auth.user?.id ?? '',
        patientName: auth.user?.name ?? '',
        doctorId: _doctorId,
        language: lang,
      );

      if (!mounted) return;
      final coins = Provider.of<CoinsProvider>(context, listen: false);
      final earned = await coins.addCoins(10);

      final responseText =
          result['user_response'] ?? result['response'] ?? 'Analysis complete.';

      setState(() {
        _isProcessing = false;
        _hasResult = true;
        _response = responseText;
        _coinsEarned = earned;
      });

      // Save MindSpace record to MongoDB
      try {
        await ApiService.post(ApiConstants.rewardsMindSpace, body: {
          'response': responseText,
          'transcript': result['transcript'] ?? '',
          'urgency': result['urgency'] ?? 'low',
          'coinsEarned': earned,
        });
      } catch (_) {}
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _hasResult = true;
        _response = 'Sorry, something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('mind_space', lang),
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
        child: SafeArea(
          child: _hasResult && _response != null
              ? _buildResultView(isDark, lang)
              : _buildRecordingView(isDark, lang),
        ),
      ),
    );
  }

  Widget _buildRecordingView(bool isDark, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status text
            Text(
              _isRecording
                  ? AppStrings.get('listening_heart', lang)
                  : _isProcessing
                      ? AppStrings.get('analyzing', lang)
                      : AppStrings.get('how_was_your_day', lang),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(),

            const SizedBox(height: 8),

            Text(
              _isRecording
                  ? '${_countdown}s'
                  : _isProcessing
                      ? AppStrings.get('give_moment', lang)
                      : AppStrings.get('tap_mic', lang),
              style: TextStyle(
                fontSize: _isRecording ? 32 : 15,
                fontWeight: _isRecording ? FontWeight.w800 : FontWeight.w400,
                color: _isRecording
                    ? AppTheme.primaryOrange
                    : (isDark ? AppTheme.darkTextGray : AppTheme.textGray),
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 48),

            // Mic button
            GestureDetector(
              onTap: _isProcessing
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isRecording ? 100 : 88,
                height: _isRecording ? 100 : 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isRecording
                      ? const LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                        )
                      : _isProcessing
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                            ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF7C4DFF))
                          .withValues(alpha: 0.4),
                      blurRadius: _isRecording ? 30 : 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording
                      ? Icons.stop_rounded
                      : _isProcessing
                          ? Icons.hourglass_top_rounded
                          : Icons.mic_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            )
                .animate(
                  onPlay:
                      _isRecording ? (c) => c.repeat(reverse: true) : null,
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: _isRecording
                      ? const Offset(1.1, 1.1)
                      : const Offset(1, 1),
                  duration: 800.ms,
                ),

            const SizedBox(height: 48),

            // Subtitle
            if (!_isRecording && !_isProcessing)
              Text(
                AppStrings.get('share_your_mind', lang),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextDim : AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(bool isDark, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          // Coins earned
          if (_coinsEarned > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppStrings.format(
                    'coins_earned', lang, {'coins': '$_coinsEarned'}),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: AppTheme.spacingMedium),

          // Response card
          GlassCard(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppStrings.get('mindbot', lang),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _response!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? AppTheme.darkTextGray
                        : AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: AppTheme.spacingLarge),

          // Record again button
          GestureDetector(
            onTap: () {
              setState(() {
                _hasResult = false;
                _response = null;
                _coinsEarned = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.get('tap_mic', lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
