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
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/screens/dashboard/patient_dashboard_screen.dart';
import 'package:hearme/screens/dashboard/doctor_dashboard_screen.dart';
import 'package:hearme/screens/auth/role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ApiService.setToken(auth.token);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => auth.isDoctor
              ? const DoctorDashboardScreen()
              : const PatientDashboardScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final lang = Provider.of<LocaleProvider>(context).languageCode;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      const ThemeToggleButton(),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingXXLarge),

                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.orangeGradient,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Title
                  Text(
                    AppStrings.get('welcome_back', lang),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppTheme.darkTextLight : AppTheme.textDark,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: AppTheme.spacingSmall),

                  Text(
                    AppStrings.get('sign_in_to_account', lang),
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: AppTheme.spacingXXLarge),

                  // Email field
                  AuthTextField(
                    controller: _emailController,
                    hintText: AppStrings.get('email', lang),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                  const SizedBox(height: AppTheme.spacingMedium),

                  // Password field
                  AuthTextField(
                    controller: _passwordController,
                    hintText: AppStrings.get('password', lang),
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark
                            ? AppTheme.darkTextDim
                            : AppTheme.textLight,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                  const SizedBox(height: AppTheme.spacingXLarge),

                  // Login button
                  AnimatedButton(
                    text: AppStrings.get('login', lang),
                    icon: Icons.login_rounded,
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _login,
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.get('dont_have_account', lang),
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextGray
                              : AppTheme.textGray,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppStrings.get('register', lang),
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
