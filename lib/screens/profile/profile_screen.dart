import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:hearme/core/theme/app_theme.dart';
import 'package:hearme/core/theme/theme_provider.dart';
import 'package:hearme/core/providers/auth_provider.dart';
import 'package:hearme/core/widgets/glass_card.dart';
import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  // Common fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Patient fields
  late TextEditingController _dobController;
  late TextEditingController _emergencyController;
  String? _bloodGroup;

  // Doctor fields
  late TextEditingController _specController;
  late TextEditingController _licenseController;
  late TextEditingController _hospitalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _emergencyController = TextEditingController();
    _specController = TextEditingController();
    _licenseController = TextEditingController();
    _hospitalController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emergencyController.dispose();
    _specController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.get(ApiConstants.profile);
      setState(() {
        _profile = data;
        _loading = false;
        _populateControllers();
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _populateControllers() {
    if (_profile == null) return;
    _nameController.text = _profile!['name'] ?? '';
    _phoneController.text = _profile!['phone'] ?? '';
    _dobController.text = _profile!['dob'] ?? '';
    _emergencyController.text = _profile!['emergencyContact'] ?? '';
    _bloodGroup = _profile!['bloodGroup'];
    _specController.text = _profile!['specialization'] ?? '';
    _licenseController.text = _profile!['licenseNumber'] ?? '';
    _hospitalController.text = _profile!['hospital'] ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_isPatient) {
        body['dob'] = _dobController.text.trim();
        body['bloodGroup'] = _bloodGroup;
        body['emergencyContact'] = _emergencyController.text.trim();
      } else {
        body['specialization'] = _specController.text.trim();
        body['licenseNumber'] = _licenseController.text.trim();
        body['hospital'] = _hospitalController.text.trim();
      }

      await ApiService.put(ApiConstants.profile, body: body);

      // Update local auth provider name
      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (_nameController.text.trim() != auth.user?.name) {
          // Reload profile to keep auth in sync
          await auth.refreshUser();
        }
      }

      setState(() {
        _editing = false;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated'),
            backgroundColor: const Color(0xFF4ECDC4),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update profile'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  bool get _isPatient => _profile?['role'] == 'patient';

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
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
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              onPressed: () {
                if (_editing) {
                  _saveProfile();
                } else {
                  setState(() => _editing = true);
                }
              },
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                  : Icon(
                      _editing ? Icons.check_rounded : Icons.edit_rounded,
                      color: AppTheme.primaryOrange,
                    ),
            ),
        ],
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
            : _profile == null
                ? Center(
                    child: Text(
                      'Failed to load profile',
                      style: TextStyle(
                        color:
                            isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isPatient
                                ? AppTheme.orangeGradient
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                          ),
                          child: Center(
                            child: Text(
                              (auth.user?.name ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 36,
                              ),
                            ),
                          ),
                        ).animate().scale(
                              begin: const Offset(0.8, 0.8),
                              duration: 400.ms,
                              curve: Curves.easeOut,
                            ),

                        const SizedBox(height: 10),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_isPatient
                                    ? const Color(0xFF4ECDC4)
                                    : const Color(0xFF667EEA))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isPatient ? 'Patient' : 'Doctor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isPatient
                                  ? const Color(0xFF4ECDC4)
                                  : const Color(0xFF667EEA),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Unique code
                        Text(
                          _profile!['uniqueCode'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.darkTextDim
                                : AppTheme.textLight,
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // Common fields
                        _buildSection(
                          isDark: isDark,
                          title: 'Personal Info',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildField(
                              isDark: isDark,
                              label: 'Full Name',
                              controller: _nameController,
                              icon: Icons.badge_outlined,
                            ),
                            _buildField(
                              isDark: isDark,
                              label: 'Email',
                              value: _profile!['email'] ?? '',
                              icon: Icons.email_outlined,
                              readOnly: true,
                            ),
                            _buildField(
                              isDark: isDark,
                              label: 'Phone',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        // Role-specific fields
                        if (_isPatient)
                          _buildSection(
                            isDark: isDark,
                            title: 'Health Info',
                            icon: Icons.favorite_outline_rounded,
                            children: [
                              _buildField(
                                isDark: isDark,
                                label: 'Date of Birth',
                                controller: _dobController,
                                icon: Icons.cake_outlined,
                              ),
                              _buildDropdownField(
                                isDark: isDark,
                                label: 'Blood Group',
                                value: _bloodGroup,
                                items: const [
                                  'A+', 'A-', 'B+', 'B-',
                                  'AB+', 'AB-', 'O+', 'O-',
                                ],
                                icon: Icons.water_drop_outlined,
                                onChanged: (v) =>
                                    setState(() => _bloodGroup = v),
                              ),
                              _buildField(
                                isDark: isDark,
                                label: 'Emergency Contact',
                                controller: _emergencyController,
                                icon: Icons.emergency_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms)
                        else
                          _buildSection(
                            isDark: isDark,
                            title: 'Professional Info',
                            icon: Icons.medical_services_outlined,
                            children: [
                              _buildField(
                                isDark: isDark,
                                label: 'Specialization',
                                controller: _specController,
                                icon: Icons.school_outlined,
                              ),
                              _buildField(
                                isDark: isDark,
                                label: 'License Number',
                                controller: _licenseController,
                                icon: Icons.verified_outlined,
                              ),
                              _buildField(
                                isDark: isDark,
                                label: 'Hospital',
                                controller: _hospitalController,
                                icon: Icons.local_hospital_outlined,
                              ),
                              _buildField(
                                isDark: isDark,
                                label: 'Patients',
                                value:
                                    '${_profile!['patientCount'] ?? 0} linked',
                                icon: Icons.people_outline_rounded,
                                readOnly: true,
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: AppTheme.spacingMedium),

                        // Member since
                        _buildSection(
                          isDark: isDark,
                          title: 'Account',
                          icon: Icons.info_outline_rounded,
                          children: [
                            _buildField(
                              isDark: isDark,
                              label: 'Member Since',
                              value: _formatDate(_profile!['createdAt']),
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: AppTheme.spacingLarge),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18,
                  color: isDark ? AppTheme.darkTextGray : AppTheme.textGray),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextGray : AppTheme.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required bool isDark,
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? value,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    final isReadOnly = readOnly || !_editing;
    final displayValue = value ?? controller?.text ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: isDark ? AppTheme.darkTextDim : AppTheme.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: isReadOnly
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextDim
                              : AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayValue.isEmpty ? '—' : displayValue,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textDark,
                        ),
                      ),
                    ],
                  )
                : TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppTheme.darkTextLight
                          : AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextDim
                            : AppTheme.textLight,
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkTextDim.withValues(alpha: 0.3)
                              : AppTheme.textLight.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppTheme.primaryOrange),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required bool isDark,
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    if (!_editing) {
      return _buildField(
        isDark: isDark,
        label: label,
        value: value ?? '',
        icon: icon,
        readOnly: true,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: isDark ? AppTheme.darkTextDim : AppTheme.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppTheme.darkTextDim : AppTheme.textLight,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkTextDim.withValues(alpha: 0.3)
                        : AppTheme.textLight.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryOrange),
                ),
              ),
              dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark ? AppTheme.darkTextLight : AppTheme.textDark,
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
