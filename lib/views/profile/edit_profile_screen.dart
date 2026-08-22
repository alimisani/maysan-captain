import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/image_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/aurora_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/user_avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  String? _avatarUrl;
  bool _obscureCurrentPassword = false;
  bool _obscureNewPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentPasswordController = TextEditingController(text: user?.password ?? '33221144');
    _newPasswordController = TextEditingController();
    _avatarUrl = user?.avatarUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshCurrentUser();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تغيير الصورة الشخصية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AuroraTheme.primaryBlue),
              title: const Text('اختيار من المعرض (Gallery)'),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await ImageService.pickAndCompressAvatar(source: ImageSource.gallery);
                if (res != null && mounted) {
                  setState(() => _avatarUrl = res);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AuroraTheme.accentEmerald),
              title: const Text('التقاط بالكاميرا (Camera)'),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await ImageService.pickAndCompressAvatar(source: ImageSource.camera);
                if (res != null && mounted) {
                  setState(() => _avatarUrl = res);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedPassword = _newPasswordController.text.trim().isNotEmpty
          ? _newPasswordController.text.trim()
          : _currentPasswordController.text.trim();

      final updatedProfile = auth.currentUser!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: updatedPassword,
        avatarUrl: _avatarUrl,
      );

      await SupabaseService().updateProfile(
        updatedProfile,
        newPassword: updatedPassword,
      );

      await auth.setCurrentUser(updatedProfile);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وتحديث بيانات الملف الشخصي بنجاح'),
            backgroundColor: AuroraTheme.accentEmerald,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AuroraTheme.accentRose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark ? const Color(0xDD0F172A) : Colors.white,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'تعديل الملف الشخصي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar Display with change button
                        Center(
                          child: UserAvatarWidget(
                            avatarUrl: _avatarUrl,
                            radius: 46,
                            showEditBadge: true,
                            onTap: _pickAvatar,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Role & Rating Tag
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: user?.isAdmin ?? false
                                  ? AuroraTheme.accentAmber.withValues(alpha: 0.15)
                                  : AuroraTheme.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: user?.isAdmin ?? false
                                    ? AuroraTheme.accentAmber
                                    : AuroraTheme.primaryBlue,
                              ),
                            ),
                            child: Text(
                              user?.isAdmin ?? false
                                  ? 'المدير العام (Super Admin)'
                                  : (user?.isDriver ?? false
                                      ? 'كابتن معتمد | تقييم: ${user?.rating} ⭐'
                                      : 'زبون | تقييم: ${user?.rating} ⭐'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: user?.isAdmin ?? false
                                    ? AuroraTheme.accentAmber
                                    : (isDark ? Colors.white : AuroraTheme.primaryBlue),
                              ),
                            ),
                          ),
                        ),

                        if (user?.isDriver ?? false) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: (user?.isSubscriptionValid ?? false)
                                    ? AuroraTheme.accentEmerald.withValues(alpha: 0.15)
                                    : AuroraTheme.accentAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (user?.isSubscriptionValid ?? false)
                                      ? AuroraTheme.accentEmerald
                                      : AuroraTheme.accentAmber,
                                ),
                              ),
                              child: Text(
                                user?.subscriptionBadgeText ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  color: (user?.isSubscriptionValid ?? false)
                                      ? AuroraTheme.accentEmerald
                                      : AuroraTheme.accentAmber,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Edit Fields Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1),
                            ),
                            boxShadow: const [
                              BoxShadow(color: Color(0x15000000), blurRadius: 16, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              CustomTextField(
                                controller: _nameController,
                                label: loc.translate('name'),
                                hint: 'الاسم الكامل',
                                prefixIcon: Icons.person_rounded,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                              ),
                              const SizedBox(height: 16),

                              // Email
                              CustomTextField(
                                controller: _emailController,
                                label: loc.translate('email'),
                                hint: 'example@email.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_rounded,
                              ),
                              const SizedBox(height: 16),

                              // Phone
                              CustomTextField(
                                controller: _phoneController,
                                label: loc.translate('phone'),
                                hint: '07800000000',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_rounded,
                              ),
                              const SizedBox(height: 16),

                              // Current Password (Visible / Toggleable)
                              CustomTextField(
                                controller: _currentPasswordController,
                                label: 'كلمة المرور الحالية (المسجلة في حسابك)',
                                hint: 'كلمة المرور الحالية',
                                prefixIcon: Icons.lock_rounded,
                                obscureText: _obscureCurrentPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrentPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscureCurrentPassword = !_obscureCurrentPassword);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // New Password (Optional)
                              CustomTextField(
                                controller: _newPasswordController,
                                label: 'تغيير كلمة المرور (اختياري)',
                                hint: 'اتركه فارغاً إذا كنت لا تريد التغيير',
                                prefixIcon: Icons.password_rounded,
                                obscureText: _obscureNewPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        AuroraButton(
                          text: 'حفظ التعديلات',
                          isLoading: _isLoading,
                          onPressed: _handleSave,
                        ),
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
}
