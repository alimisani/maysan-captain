import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/state/booking_provider.dart';
import '../driver_quick_sheet.dart';
import '../maysan_map_widget.dart';
import '../ride_booking_sheet.dart';
import '../widgets/ad_banner_carousel_widget.dart';
import '../widgets/favorite_places_row_widget.dart';

class LayoutClassicGlass extends StatelessWidget {
  final bool isDark;
  final AppLocalizations loc;

  const LayoutClassicGlass({
    super.key,
    required this.isDark,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final user = auth.currentUser;
    final isDriver = user?.isDriver ?? false;
    final activeBanners = booking.activeBanners;

    return Stack(
      children: [
        // 1. Fullscreen Interactive Map Layer
        const MaysanMapWidget(),

        // 2. Middle Elements: Ad Banners & Favorites (Positioned cleanly under Top Bar)
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Commercial Ads Banner Carousel (if active ads exist)
              if (activeBanners.isNotEmpty && !isDriver)
                AdBannerCarouselWidget(
                  banners: activeBanners,
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),

              // Favorite Places Quick Selection Row
              if (!isDriver)
                FavoritePlacesRowWidget(
                  isDark: isDark,
                  onPlaceSelected: (place) {
                    booking.setDropoffLocation(
                      place.coordinates,
                      customAddress: place.title,
                      isArabic: loc.isArabic,
                    );
                  },
                ),
            ],
          ),
        ),

        // 3. Bottom Interactive Sheet (Ride Booking / Driver Quick Sheet)
        Align(
          alignment: Alignment.bottomCenter,
          child: isDriver ? const DriverQuickSheet() : const RideBookingSheet(),
        ),
      ],
    );
  }
}
