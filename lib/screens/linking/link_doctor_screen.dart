import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/animated_button.dart';
import 'package:hearme/core/widgets/auth_text_field.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class LinkDoctorScreen extends StatefulWidget {
  const LinkDoctorScreen({super.key});

  @override
  State<LinkDoctorScreen> createState() => _LinkDoctorScreenState();
}

class _LinkDoctorScreenState extends State<LinkDoctorScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _linkedDoctorName;

  @override
  void initState() {
    super.initState();
    _loadLinkedDoctor();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedDoctor() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      ApiService.setToken(auth.token);
      final result = await ApiService.get(ApiConstants.patientDoctor);
      if (result['doctor'] != null) {
        setState(() {
          _linkedDoctorName = result['doctor']['name'];
        });
      }
    } catch (_) {}
  }

  Future<void> _linkDoctor() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      ApiService.setToken(auth.token);
      final result = await ApiService.post(
        ApiConstants.patientLink,
        body: {'doctorCode': code},
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _linkedDoctorName = result['doctor']?['name'] ?? 'Doctor';
      });
      _codeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully linked to doctor!'),
          backgroundColor: Color(0xFF4ECDC4),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('link_to_doctor', lang),
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
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            children: [
              // Currently linked
              if (_linkedDoctorName != null)
                GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('currently_linked', lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextGray
                                  : AppTheme.textGray,
                            ),
                          ),
                          Text(
                            'Dr. $_linkedDoctorName',
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
                      const Spacer(),
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF4ECDC4),
                        size: 24,
                      ),
                    ],
                  ),
                ).animate().fadeIn()
              else
                GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: isDark
                            ? AppTheme.darkTextDim
                            : AppTheme.textLight,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.get('not_linked', lang),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextGray
                              : AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: AppTheme.spacingXLarge),

              // Description
              Text(
                AppStrings.get('link_doctor_desc', lang),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Code input
              AuthTextField(
                controller: _codeController,
                hintText: AppStrings.get('enter_doctor_code', lang),
                prefixIcon: Icons.qr_code_rounded,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              // Link button
              AnimatedButton(
                text: AppStrings.get('link', lang),
                icon: Icons.link_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _linkDoctor,
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
