import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../driver/vehicle_registration_screen.dart';
import '../home/home_screen.dart';
import '../widgets/aurora_background.dart';
import '../widgets/aurora_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glass_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  String _selectedRole = 'user'; // 'user' or 'driver'
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isReferralFieldVisible = true;

  @override
  void initState() {
    super.initState();
    _checkReferralSettings();
  }

  Future<void> _checkReferralSettings() async {
    try {
      final s = await SupabaseService().getReferralSettings();
      if (mounted) {
        setState(() {
          _isReferralFieldVisible = s['is_referral_field_visible'] == true && s['is_referral_system_enabled'] == true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('passwordsDontMatch')),
          backgroundColor: AuroraTheme.accentRose,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
      referralCode: _referralCodeController.text.trim().isNotEmpty ? _referralCodeController.text.trim() : null,
    );

    if (success && mounted) {
      if (_selectedRole == 'driver') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const VehicleRegistrationScreen(isFirstTime: true),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AuroraTheme.accentRose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AuroraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Text(
                      loc.translate('register'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 6),

                    Text(
                      'انضم إلى شبكة كابتن ميسان لخدمات النقل والتوصيل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 24),

                    // Glass Card
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      borderRadius: 24,
                      glow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role Selector (User vs Driver)
                          Text(
                            loc.translate('accountType'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _RoleChip(
                                  title: loc.translate('passengerUser'),
                                  icon: Icons.person_pin_circle_rounded,
                                  isSelected: _selectedRole == 'user',
                                  onTap: () => setState(() => _selectedRole = 'user'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RoleChip(
                                  title: loc.translate('captainDriver'),
                                  icon: Icons.drive_eta_rounded,
                                  isSelected: _selectedRole == 'driver',
                                  onTap: () => setState(() => _selectedRole = 'driver'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Name
                          CustomTextField(
                            controller: _nameController,
                            label: loc.translate('name'),
                            hint: 'الاسم الثلاثي أو المستعار',
                            prefixIcon: Icons.person_rounded,
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                          ),

                          const SizedBox(height: 14),

                          // Email
                          CustomTextField(
                            controller: _emailController,
                            label: loc.translate('email'),
                            hint: 'example@domain.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_rounded,
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                          ),

                          const SizedBox(height: 14),

                          // Phone
                          CustomTextField(
                            controller: _phoneController,
                            label: loc.translate('phone'),
                            hint: '07800000000',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_rounded,
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                          ),

                          const SizedBox(height: 14),

                          // Password
                          CustomTextField(
                            controller: _passwordController,
                            label: loc.translate('password'),
                            hint: '••••••••',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                          ),

                          const SizedBox(height: 14),

                          // Confirm Password
                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: loc.translate('confirmPassword'),
                            hint: '••••••••',
                            prefixIcon: Icons.lock_clock_rounded,
                            obscureText: _obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirm = !_obscureConfirm);
                              },
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                          ),

                          if (_isReferralFieldVisible) ...[
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _referralCodeController,
                              label: 'رمز الإحالة / كود الدعوة (اختياري)',
                              hint: 'أدخل كود الكابتن الداعي (مثال: u2)',
                              prefixIcon: Icons.card_giftcard_rounded,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Register Button
                          AuroraButton(
                            text: loc.translate('registerButton'),
                            isLoading: auth.isLoading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          loc.translate('haveAccount'),
                          style: TextStyle(
                            color: isDark ? AuroraTheme.primaryCyan : AuroraTheme.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected ? AuroraTheme.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9)),
          border: Border.all(
            color: isSelected
                ? AuroraTheme.primaryCyan
                : (isDark ? const Color(0x2238BDF8) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : const Color(0xFF475569)),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
