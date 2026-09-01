import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../../../models/favorite_place.dart';
import 'add_favorite_place_dialog.dart';

class FavoritePlacesRowWidget extends StatelessWidget {
  final Function(FavoritePlace place) onPlaceSelected;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const FavoritePlacesRowWidget({
    super.key,
    required this.onPlaceSelected,
    required this.isDark,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'university':
        return Icons.school_rounded;
      case 'family':
        return Icons.favorite_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'home':
        return const Color(0xFF10B981);
      case 'work':
        return const Color(0xFF3B82F6);
      case 'university':
        return const Color(0xFF8B5CF6);
      case 'family':
        return const Color(0xFFEC4899);
      case 'shopping':
        return const Color(0xFFF59E0B);
      default:
        return AuroraTheme.primaryCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final favorites = booking.favoritePlaces;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(Icons.bookmark_rounded, size: 16, color: AuroraTheme.primaryCyan),
              const SizedBox(width: 6),
              const Text(
                'الوجهات والأماكن المفضلة',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  if (user != null) {
                    AddFavoritePlaceDialog.show(
                      context,
                      initialLocation: booking.pickupLocation,
                      initialAddress: booking.pickupAddress,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 14, color: AuroraTheme.primaryCyan),
                      SizedBox(width: 4),
                      Text(
                        'إضافة مكان',
                        style: TextStyle(fontSize: 11.5, color: AuroraTheme.primaryCyan, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (favorites.isEmpty) ...[
                  // Default helper pills if user has no saved favorites yet
                  _buildQuickAddPill(context, 'المنزل', 'home', Icons.home_rounded, const Color(0xFF10B981), booking),
                  const SizedBox(width: 8),
                  _buildQuickAddPill(context, 'العمل', 'work', Icons.work_rounded, const Color(0xFF3B82F6), booking),
                  const SizedBox(width: 8),
                  _buildQuickAddPill(context, 'الجامعة', 'university', Icons.school_rounded, const Color(0xFF8B5CF6), booking),
                  const SizedBox(width: 8),
                  _buildQuickAddPill(context, 'الأهل', 'family', Icons.favorite_rounded, const Color(0xFFEC4899), booking),
                ] else ...[
                  ...favorites.map((place) => _buildPlaceItem(context, place, booking)),
                  const SizedBox(width: 8),
                  // Add New button at the end
                  InkWell(
                    onTap: () {
                      if (user != null) {
                        AddFavoritePlaceDialog.show(
                          context,
                          initialLocation: booking.pickupLocation,
                          initialAddress: booking.pickupAddress,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AuroraTheme.primaryCyan.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: AuroraTheme.primaryCyan),
                          SizedBox(width: 4),
                          Text('إضافة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AuroraTheme.primaryCyan)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem(BuildContext context, FavoritePlace place, BookingProvider booking) {
    final color = _getCategoryColor(place.category);
    final icon = _getCategoryIcon(place.category);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPlaceSelected(place),
          onLongPress: () => _showPlaceOptions(context, place, booking),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x22000000) : const Color(0x0C000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddPill(
    BuildContext context,
    String title,
    String category,
    IconData icon,
    Color color,
    BookingProvider booking,
  ) {
    return InkWell(
      onTap: () {
        AddFavoritePlaceDialog.show(
          context,
          initialLocation: booking.pickupLocation,
          initialAddress: booking.pickupAddress,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              '+ $title',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceOptions(BuildContext context, FavoritePlace place, BookingProvider booking) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_getCategoryIcon(place.category), color: _getCategoryColor(place.category)),
                  const SizedBox(width: 10),
                  Text(place.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Text(place.address, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.navigation_rounded, color: AuroraTheme.primaryCyan),
                title: const Text('تعيين كوجهة انطلاق أو وصول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  onPlaceSelected(place);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
                title: const Text('تعديل المكان المفضل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  AddFavoritePlaceDialog.show(context, existingPlace: place);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                title: const Text('حذف من المفضلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (user != null) {
                    await booking.deleteFavoritePlace(user.id, place.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
