import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../home/home_screen.dart';
import '../widgets/aurora_background.dart';
import '../widgets/aurora_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glass_card.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  final bool isFirstTime;
  const VehicleRegistrationScreen({super.key, this.isFirstTime = false});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  String _selectedType = 'salon';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<AuthProvider>().currentVehicle;
    if (vehicle != null) {
      _modelController.text = vehicle.model ?? '';
      _plateController.text = vehicle.plateNumber ?? '';
      _colorController.text = vehicle.color ?? '';
      _selectedType = vehicle.vehicleType;
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.registerVehicle(
        vehicleType: _selectedType,
        plateNumber: _plateController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('success')),
            backgroundColor: AuroraTheme.accentEmerald,
          ),
        );
        if (widget.isFirstTime) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AuroraTheme.accentRose,
          ),
        );
      }
    }
  }

  static const List<_VehicleTypeData> _types = [
    _VehicleTypeData('salon', 'صالون (تكسي)', Icons.local_taxi_rounded, Color(0xFFF59E0B), Color(0xFFD97706)),
    _VehicleTypeData('private', 'سيارة خصوصي', Icons.directions_car_filled_rounded, Color(0xFF38BDF8), Color(0xFF0EA5E9)),
    _VehicleTypeData('motorcycle', 'دراجة نارية', Icons.two_wheeler_rounded, Color(0xFF34D399), Color(0xFF10B981)),
    _VehicleTypeData('tuk_tuk', 'ستوتة / تكتك', Icons.electric_rickshaw_rounded, Color(0xFFA78BFA), Color(0xFF7C3AED)),
    _VehicleTypeData('pickup', 'بيك آب / شحن', Icons.local_shipping_rounded, Color(0xFFF87171), Color(0xFFEF4444)),
    _VehicleTypeData('vip', 'سيارة VIP فارهة', Icons.star_rounded, Color(0xFFFCD34D), Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('registerVehicle')),
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: AuroraBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: GlassCard(
              padding: const EdgeInsets.all(22),
              borderRadius: 24,
              glow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AuroraTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(loc.translate('vehicleType'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                    children: _types.map((vt) => _buildCard(vt, isDark)).toList(),
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _modelController,
                    label: loc.translate('vehicleModel'),
                    hint: 'مثال: تويوتا كورولا 2022 / سايبا / سنتافي',
                    prefixIcon: Icons.car_repair_rounded,
                    validator: (val) => val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _plateController,
                    label: loc.translate('plateNumber'),
                    hint: 'مثال: ميسان 12345 خصوصي / أجرة',
                    prefixIcon: Icons.pin_rounded,
                    validator: (val) => val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _colorController,
                    label: loc.translate('vehicleColor'),
                    hint: 'مثال: أبيض / أصفر / فضي / أسود',
                    prefixIcon: Icons.palette_rounded,
                    validator: (val) => val == null || val.trim().isEmpty ? loc.translate('fillAllFields') : null,
                  ),
                  const SizedBox(height: 24),
                  AuroraButton(text: loc.translate('save'), isLoading: _isSaving, onPressed: _handleSave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(_VehicleTypeData vt, bool isDark) {
    final sel = _selectedType == vt.key;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = vt.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: sel ? LinearGradient(colors: [vt.c1, vt.c2], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: sel ? null : (isDark ? const Color(0x331E293B) : const Color(0xFFF1F5F9)),
          border: Border.all(
            color: sel ? vt.c1 : (isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1)),
            width: sel ? 2 : 1,
          ),
          boxShadow: sel ? [BoxShadow(color: vt.c1.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? Colors.white.withValues(alpha: 0.2) : vt.c1.withValues(alpha: 0.15),
              ),
              child: Icon(vt.icon, color: sel ? Colors.white : vt.c1, size: 24),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                vt.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                  color: sel ? Colors.white : (isDark ? const Color(0xCCFFFFFF) : const Color(0xFF1E293B)),
                  height: 1.3,
                ),
              ),
            ),
            if (sel)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 13),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTypeData {
  final String key;
  final String label;
  final IconData icon;
  final Color c1;
  final Color c2;
  const _VehicleTypeData(this.key, this.label, this.icon, this.c1, this.c2);
}
