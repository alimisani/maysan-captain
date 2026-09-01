import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/location_service.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../../../models/favorite_place.dart';
import '../location_picker_sheet.dart';

class AddFavoritePlaceDialog extends StatefulWidget {
  final FavoritePlace? existingPlace;
  final LatLng? initialLocation;
  final String? initialAddress;

  const AddFavoritePlaceDialog({
    super.key,
    this.existingPlace,
    this.initialLocation,
    this.initialAddress,
  });

  static Future<void> show(
    BuildContext context, {
    FavoritePlace? existingPlace,
    LatLng? initialLocation,
    String? initialAddress,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddFavoritePlaceDialog(
        existingPlace: existingPlace,
        initialLocation: initialLocation,
        initialAddress: initialAddress,
      ),
    );
  }

  @override
  State<AddFavoritePlaceDialog> createState() => _AddFavoritePlaceDialogState();
}

class _AddFavoritePlaceDialogState extends State<AddFavoritePlaceDialog> {
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'home';
  late LatLng _selectedCoordinates;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'home', 'label': 'المنزل', 'icon': Icons.home_rounded, 'color': Color(0xFF10B981)},
    {'key': 'work', 'label': 'العمل', 'icon': Icons.work_rounded, 'color': Color(0xFF3B82F6)},
    {'key': 'university', 'label': 'الجامعة', 'icon': Icons.school_rounded, 'color': Color(0xFF8B5CF6)},
    {'key': 'family', 'label': 'الأهل', 'icon': Icons.favorite_rounded, 'color': Color(0xFFEC4899)},
    {'key': 'shopping', 'label': 'السوق', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFF59E0B)},
    {'key': 'custom', 'label': 'مخصص', 'icon': Icons.place_rounded, 'color': Color(0xFF06B6D4)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPlace != null) {
      _titleController.text = widget.existingPlace!.title;
      _addressController.text = widget.existingPlace!.address;
      _selectedCategory = widget.existingPlace!.category;
      _selectedCoordinates = widget.existingPlace!.coordinates;
    } else {
      _selectedCoordinates = widget.initialLocation ?? const LatLng(31.8418, 47.1465);
      _addressController.text = widget.initialAddress ?? 'جاري التحديد...';
      _titleController.text = 'المنزل';

      if (widget.initialAddress == null) {
        _resolveInitialAddress();
      }
    }
  }

  Future<void> _resolveInitialAddress() async {
    final addr = await LocationService.getRealAddress(_selectedCoordinates, isArabic: true);
    if (mounted) {
      setState(() {
        _addressController.text = addr;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickFromMap() async {
    final result = await LocationPickerSheet.show(
      context,
      title: 'اختر موقع المكان المفضل',
      initialLocation: _selectedCoordinates,
      isPickup: false,
    );

    if (result != null && mounted) {
      final point = result['location'] as LatLng;
      final address = result['address'] as String;
      setState(() {
        _selectedCoordinates = point;
        _addressController.text = address;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم المكان')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final place = FavoritePlace(
        id: widget.existingPlace?.id ?? const Uuid().v4(),
        userId: user.id,
        title: title,
        address: address.isNotEmpty ? address : 'ميسان',
        latitude: _selectedCoordinates.latitude,
        longitude: _selectedCoordinates.longitude,
        category: _selectedCategory,
        createdAt: widget.existingPlace?.createdAt ?? DateTime.now(),
      );

      await booking.addFavoritePlace(place);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPlace != null ? 'تم تعديل المكان المفضل بنجاح' : 'تم حفظ المكان المفضل بنجاح 🌟'),
            backgroundColor: AuroraTheme.accentEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bookmark_add_rounded, color: AuroraTheme.primaryCyan, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.existingPlace != null ? 'تعديل المكان المفضل' : 'إضافة مكان مفضل جديد',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Category Chips Selector
            const Text(
              'نوع المكان / التصنيف:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['key'];
                final color = cat['color'] as Color;
                return ChoiceChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : color),
                  label: Text(cat['label'] as String),
                  selected: isSelected,
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat['key'] as String;
                        if (_titleController.text.isEmpty || _categories.any((c) => c['label'] == _titleController.text)) {
                          _titleController.text = cat['label'] as String;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'اسم المكان (مثلاً: المنزل، مكتبي، بيت جدي)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.label_outline_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Address & Map Picker Field
            TextField(
              controller: _addressController,
              readOnly: true,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'العنوان والإحداثيات',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_rounded, color: AuroraTheme.primaryCyan),
                  tooltip: 'تغيير وتحديد من الخريطة',
                  onPressed: _pickFromMap,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),

            // Change map location button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AuroraTheme.primaryCyan.withValues(alpha: 0.5)),
              ),
              icon: const Icon(Icons.pin_drop_rounded, size: 18, color: AuroraTheme.primaryCyan),
              label: const Text('تحديد وتعديل الموقع على الخريطة', style: TextStyle(fontSize: 12.5, color: AuroraTheme.primaryCyan)),
              onPressed: _pickFromMap,
            ),
            const SizedBox(height: 20),

            // Actions Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuroraTheme.primaryCyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            widget.existingPlace != null ? 'حفظ التعديل' : 'إضافة للمفضلة',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
