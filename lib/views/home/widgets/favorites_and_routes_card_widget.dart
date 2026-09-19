import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/state/booking_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../../../models/favorite_place.dart';
import '../../../models/saved_route.dart';
import 'favorite_places_row_widget.dart';
import 'saved_routes_widget.dart';

class FavoritesAndRoutesCardWidget extends StatefulWidget {
  final bool isDark;
  final Function(FavoritePlace place)? onPlaceSelected;
  final Function(SavedRoute route)? onRouteSelected;

  const FavoritesAndRoutesCardWidget({
    super.key,
    required this.isDark,
    this.onPlaceSelected,
    this.onRouteSelected,
  });

  @override
  State<FavoritesAndRoutesCardWidget> createState() => _FavoritesAndRoutesCardWidgetState();
}

class _FavoritesAndRoutesCardWidgetState extends State<FavoritesAndRoutesCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadExpandedState();
  }

  Future<void> _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('card_favorites_expanded');
    if (saved != null && mounted) {
      setState(() => _isExpanded = saved);
    }
  }

  void _toggleExpanded() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('card_favorites_expanded', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isDark
                ? const Color(0x3338BDF8)
                : AuroraTheme.primaryCyan.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isDark ? Colors.black26 : const Color(0x0C000000),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with toggle collapse/expand
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AuroraTheme.primaryCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_added_rounded,
                        size: 18,
                        color: AuroraTheme.primaryCyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الوجهات المفضلة وخطوط السير',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _isExpanded
                                ? 'الوصول السريع للأماكن المعتادة وخطوط السير اليومية'
                                : 'انقر هنا لإظهار الوجهات المفضلة وخطوط السير',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0x33334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'طي' : 'إظهار',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: widget.isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content when expanded
            AnimatedCrossFade(
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: widget.isDark ? const Color(0x2238BDF8) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 8),

                  // 1. Favorite Places Section
                  FavoritePlacesRowWidget(
                    isDark: widget.isDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onPlaceSelected: widget.onPlaceSelected ??
                        (place) {
                          booking.setDropoffLocation(
                            place.coordinates,
                            customAddress: place.address,
                            isArabic: loc.isArabic,
                          );
                        },
                  ),

                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: widget.isDark ? const Color(0x1538BDF8) : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 4),

                  // 2. Saved Routes Section
                  SavedRoutesWidget(
                    isDark: widget.isDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onRouteSelected: widget.onRouteSelected ??
                        (route) {
                          booking.applySavedRoute(route, isArabic: loc.isArabic);
                        },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState:
                  _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
