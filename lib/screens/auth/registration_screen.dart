import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/locale/app_strings.dart';
import 'package:hearme/core/locale/locale_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/providers/coins_provider.dart';
import 'package:hearme/core/widgets/animated_button.dart';
import 'package:hearme/core/widgets/auth_text_field.dart';
import 'package:hearme/core/widgets/theme_toggle_button.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/screens/dashboard/patient_dashboard_screen.dart';
import 'package:hearme/screens/dashboard/doctor_dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;

  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Patient fields
  final _dobController = TextEditingController();
  String _bloodGroup = 'O+';
  final _emergencyContactController = TextEditingController();

  // Doctor fields
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hospitalController = TextEditingController();

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _emergencyContactController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': widget.role,
    };

    if (_phoneController.text.isNotEmpty) {
      data['phone'] = _phoneController.text.trim();
    }

    if (widget.role == 'patient') {
      if (_dobController.text.isNotEmpty) data['dob'] = _dobController.text;
      data['bloodGroup'] = _bloodGroup;
      if (_emergencyContactController.text.isNotEmpty) {
        data['emergencyContact'] = _emergencyContactController.text.trim();
      }
    } else {
      if (_specializationController.text.isNotEmpty) {
        data['specialization'] = _specializationController.text.trim();
      }
      if (_licenseController.text.isNotEmpty) {
        data['licenseNumber'] = _licenseController.text.trim();
      }
      if (_hospitalController.text.isNotEmpty) {
        data['hospital'] = _hospitalController.text.trim();
      }
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(data);

    if (!mounted) return;

    if (success) {
      ApiService.setToken(auth.token);
      final coinsProvider =
          Provider.of<CoinsProvider>(context, listen: false);
      coinsProvider.loadFromServer();
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
          content: Text(auth.error ?? 'Registration failed'),
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
    final isPatient = widget.role == 'patient';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Row(
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
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: isPatient
                            ? const LinearGradient(
                                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppStrings.get(widget.role, lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const ThemeToggleButton(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          AppStrings.get('create_account', lang),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextLight
                                : AppTheme.textDark,
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Common fields
                        AuthTextField(
                          controller: _nameController,
                          hintText: AppStrings.get('full_name', lang),
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Name is required'
                              : null,
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        AuthTextField(
                          controller: _emailController,
                          hintText: AppStrings.get('email', lang),
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ).animate().fadeIn(delay: 250.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        AuthTextField(
                          controller: _phoneController,
                          hintText: AppStrings.get('phone_optional', lang),
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

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
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Must be at least 6 characters';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 350.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        AuthTextField(
                          controller: _confirmPasswordController,
                          hintText: AppStrings.get('confirm_password', lang),
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isDark
                                  ? AppTheme.darkTextDim
                                  : AppTheme.textLight,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // Role-specific fields
                        if (isPatient) ..._buildPatientFields(isDark, lang),
                        if (!isPatient) ..._buildDoctorFields(isDark, lang),

                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Register button
                        AnimatedButton(
                          text: AppStrings.get('register', lang),
                          icon: Icons.person_add_rounded,
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _register,
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: AppTheme.spacingLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPatientFields(bool isDark, String lang) {
    return [
      Text(
        'Patient Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
        ),
      ).animate().fadeIn(delay: 450.ms),

      const SizedBox(height: AppTheme.spacingMedium),

      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000, 1, 1),
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            _dobController.text =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
        child: AbsorbPointer(
          child: AuthTextField(
            controller: _dobController,
            hintText: AppStrings.get('date_of_birth', lang),
            prefixIcon: Icons.calendar_today_outlined,
          ),
        ),
      ).animate().fadeIn(delay: 475.ms),

      const SizedBox(height: AppTheme.spacingMedium),

      // Blood group dropdown
      DropdownButtonFormField<String>(
        initialValue: _bloodGroup,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.bloodtype_outlined,
            color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
            size: 20,
          ),
          filled: true,
          fillColor: isDark
              ? AppTheme.darkCard.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
        style: TextStyle(
          color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
          fontSize: 15,
        ),
        items: _bloodGroups
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _bloodGroup = v ?? 'O+'),
      ).animate().fadeIn(delay: 500.ms),

      const SizedBox(height: AppTheme.spacingMedium),

      AuthTextField(
        controller: _emergencyContactController,
        hintText: AppStrings.get('emergency_contact', lang),
        prefixIcon: Icons.emergency_outlined,
        keyboardType: TextInputType.phone,
      ).animate().fadeIn(delay: 525.ms),
    ];
  }

  List<Widget> _buildDoctorFields(bool isDark, String lang) {
    return [
      Text(
        'Doctor Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextLight : AppTheme.textDark,
        ),
      ).animate().fadeIn(delay: 450.ms),

      const SizedBox(height: AppTheme.spacingMedium),

      AuthTextField(
        controller: _specializationController,
        hintText: AppStrings.get('specialization', lang),
        prefixIcon: Icons.medical_information_outlined,
      ).animate().fadeIn(delay: 475.ms),

      const SizedBox(height: AppTheme.spacingMedium),

      AuthTextField(
        controller: _licenseController,
        hintText: AppStrings.get('license_number', lang),
        prefixIcon: Icons.badge_outlined,
      ).animate().fadeIn(delay: 500.ms),

      const SizedBox(height: AppTheme.spacingMedium),

      AuthTextField(
        controller: _hospitalController,
        hintText: AppStrings.get('hospital', lang),
        prefixIcon: Icons.local_hospital_outlined,
      ).animate().fadeIn(delay: 525.ms),
    ];
  }
}
