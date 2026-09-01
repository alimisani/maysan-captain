import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/ad_banner.dart';
import '../../../core/theme/aurora_theme.dart';

class AdBannerCarouselWidget extends StatefulWidget {
  final List<AdBanner> banners;
  final double height;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;

  const AdBannerCarouselWidget({
    super.key,
    required this.banners,
    this.height = 145,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius,
  });

  @override
  State<AdBannerCarouselWidget> createState() => _AdBannerCarouselWidgetState();
}

class _AdBannerCarouselWidgetState extends State<AdBannerCarouselWidget> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.banners.length > 1) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant AdBannerCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleBannerTap(BuildContext context, AdBanner banner) async {
    final target = banner.targetUrl.trim();
    if (target.isEmpty) {
      // Show full image dialog
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  banner.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 60),
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
      return;
    }

    try {
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try prepending https:// if missing
        if (!target.startsWith('http://') && !target.startsWith('https://') && !target.startsWith('tel:') && !target.startsWith('whatsapp:')) {
          final fixedUri = Uri.parse('https://$target');
          if (await canLaunchUrl(fixedUri)) {
            await launchUrl(fixedUri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      debugPrint('Launch banner url error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.borderRadius ?? BorderRadius.circular(22);

    return Container(
      margin: widget.margin,
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return GestureDetector(
                onTap: () => _handleBannerTap(context, banner),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? const Color(0x33000000) : const Color(0x18000000),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: r,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Ad Image
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: AuroraTheme.primaryGradient,
                            ),
                            child: const Center(
                              child: Icon(Icons.campaign_rounded, size: 48, color: Colors.white70),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.primaryCyan),
                              ),
                            );
                          },
                        ),

                        // Soft Gradient Overlay for Readability
                        if (banner.title.isNotEmpty || banner.subtitle.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),

                        // Text & Info Overlay
                        if (banner.title.isNotEmpty || banner.subtitle.isNotEmpty)
                          Positioned(
                            bottom: 12,
                            right: 16,
                            left: 16,
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
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (banner.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    banner.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 11.5,
                                      shadows: const [
                                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                        // Sponsored / Ad Tag
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'إعلان ميسان',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Dots Indicator
          if (widget.banners.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 18 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AuroraTheme.primaryCyan
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
