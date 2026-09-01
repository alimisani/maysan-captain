import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/state/booking_provider.dart';
import '../../../core/theme/aurora_theme.dart';
import '../../../models/ad_banner.dart';

class AdSlotBannerWidget extends StatefulWidget {
  final String slot; // 'main', 'medium', 'bottom'
  final EdgeInsetsGeometry margin;

  const AdSlotBannerWidget({
    super.key,
    required this.slot,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<AdSlotBannerWidget> createState() => _AdSlotBannerWidgetState();
}

class _AdSlotBannerWidgetState extends State<AdSlotBannerWidget> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  final Set<String> _recordedImpressionIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final booking = context.read<BookingProvider>();
      final banners = _getSlotBanners(booking);
      if (banners.length > 1) {
        final next = (_currentPage + 1) % banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<AdBanner> _getSlotBanners(BookingProvider booking) {
    switch (widget.slot) {
      case 'medium':
        return booking.mediumSlotBanners;
      case 'bottom':
        return booking.bottomSlotBanners;
      case 'main':
      default:
        return booking.mainSlotBanners;
    }
  }

  double _getSlotHeight() {
    switch (widget.slot) {
      case 'medium':
        return 125.0;
      case 'bottom':
        return 95.0;
      case 'main':
      default:
        return 155.0;
    }
  }

  void _recordImpression(AdBanner banner) {
    if (!_recordedImpressionIds.contains(banner.id)) {
      _recordedImpressionIds.add(banner.id);
      context.read<BookingProvider>().recordBannerView(banner.id);
    }
  }

  Future<void> _handleBannerTap(BuildContext context, AdBanner banner) async {
    // 1. Record Click
    context.read<BookingProvider>().recordBannerClick(banner.id);

    final target = banner.targetUrl.trim();
    if (target.isEmpty) {
      _showImagePreview(context, banner);
      return;
    }

    try {
      if (target.startsWith('tel:')) {
        await launchUrl(Uri.parse(target));
      } else if (target.startsWith('whatsapp:') || target.startsWith('https://wa.me/')) {
        await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
      } else if (target.startsWith('http://') || target.startsWith('https://')) {
        await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
      } else if (RegExp(r'^[0-9+]+$').hasMatch(target)) {
        await launchUrl(Uri.parse('tel:$target'));
      } else {
        await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        _showImagePreview(context, banner);
      }
    }
  }

  void _showImagePreview(BuildContext context, AdBanner banner) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, size: 60, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final banners = _getSlotBanners(booking);

    // Rule: If slot has no active banners, collapse with 0 size
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotHeight = _getSlotHeight();

    return Padding(
      padding: widget.margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: slotHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                if (index < banners.length) {
                  _recordImpression(banners[index]);
                }
              },
              itemBuilder: (context, index) {
                final banner = banners[index];
                _recordImpression(banner);
                return _buildBannerCard(context, banner, isDark);
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? AuroraTheme.primaryCyan
                        : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, AdBanner banner, bool isDark) {
    final isDiscount = banner.adType == 'discount' || banner.discountText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDiscount
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : (isDark ? const Color(0x3338BDF8) : const Color(0xFFE2E8F0)),
          width: isDiscount ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x30000000) : const Color(0x0C000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _handleBannerTap(context, banner),
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.campaign_rounded, size: 28, color: AuroraTheme.primaryCyan),
                          const SizedBox(height: 4),
                          Text(
                            banner.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient Overlay for Text Readability
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),

              // Top Badges Row (Sponsor / Discount)
              Positioned(
                top: 8,
                right: 8,
                left: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sponsor Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white30, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 11, color: AuroraTheme.primaryCyan),
                          const SizedBox(width: 4),
                          Text(
                            banner.advertiserName.isNotEmpty ? banner.advertiserName : 'إعلان مميز',
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Discount Offer Tag (if applicable)
                    if (isDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x35000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              banner.discountText.isNotEmpty ? banner.discountText : 'عرض خاص',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Title & Subtitle + Action Hint
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (banner.title.isNotEmpty)
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (banner.subtitle.isNotEmpty)
                            Text(
                              banner.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10.5,
                                shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AuroraTheme.primaryCyan,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تفاصيل',
                            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
