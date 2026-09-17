import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';
import 'aurora_button.dart';
import 'glass_card.dart';

class RatingDialog extends StatefulWidget {
  final RideOrder order;

  const RatingDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, RideOrder order) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(order: order),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedBadges = {};
  bool _isSubmitting = false;

  final List<String> _availableBadges = [
    '🚗 قيادة آمنة وهادئة',
    '✨ سيارة نظيفة وممتازة',
    '🤝 تعامل راقي ومحترم',
    '⏱️ التزام وسرعة في الوصول',
    '❄️ مكيف ممتاز ومريح',
    '🛣️ معرفة ممتازة بالطرق',
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.dismissLiveTripNotification();
    if (widget.order.customerRating != null) {
      _rating = widget.order.customerRating!;
    }
    if (widget.order.customerComment != null &&
        widget.order.customerComment!.isNotEmpty) {
      final comment = widget.order.customerComment!;
      // Check if badges were in the comment
      for (final badge in _availableBadges) {
        if (comment.contains(badge)) {
          _selectedBadges.add(badge);
        }
      }
      // Strip badges from comment text box
      final lines = comment.split('\n');
      final textLines = lines.where((l) => !_availableBadges.any((b) => l.contains(b))).toList();
      _commentController.text = textLines.join('\n').trim();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null || widget.order.driverId == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final combinedComment = _selectedBadges.isNotEmpty
          ? '${_selectedBadges.join(" • ")}\n${_commentController.text.trim()}'
          : _commentController.text.trim();

      await SupabaseService().submitReview(
        rideId: widget.order.id,
        customerId: auth.currentUser!.id,
        customerName: auth.currentUser!.name,
        driverId: widget.order.driverId!,
        rating: _rating,
        comment: combinedComment,
        isEdit: widget.order.isReviewed,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.order.isReviewed
                ? 'تم تحديث تقييمك للكابتن بنجاح ⭐'
                : 'شكراً لك! تم إرسال تقييمك للكابتن بنجاح ⭐'),
            backgroundColor: AuroraTheme.accentEmerald,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final isAlreadyEdited = widget.order.isReviewEdited;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        borderRadius: 24,
        glow: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuroraTheme.amberRoseGradient,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                widget.order.isReviewed ? 'تعديل تقييم الكابتن' : 'تقييم تجربة المشوار والكابتن',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'الكابتن: ${widget.order.driverName ?? "كابتن ميسان"} (${widget.order.vehicleInfo ?? "سيارة معتمدة"})',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              if (isAlreadyEdited) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AuroraTheme.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AuroraTheme.accentEmerald),
                  ),
                  child: const Text(
                    '✔️ تم حفظ التقييم النهائي لهذه الرحلة (تم التعديل سابقاً)',
                    style: TextStyle(fontSize: 11, color: AuroraTheme.accentEmerald, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 5 Stars selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  return IconButton(
                    padding: const EdgeInsets.all(4),
                    onPressed: isAlreadyEdited ? null : () => setState(() => _rating = starValue),
                    icon: Icon(
                      starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 38,
                    ),
                  );
                }),
              ),
              Center(
                child: Text(
                  '$_rating من 5 نجوم',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Multi-select Feature Badges
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'مميزات أعجبتك في الكابتن والرحلة:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableBadges.map((badge) {
                  final isSelected = _selectedBadges.contains(badge);
                  return FilterChip(
                    label: Text(badge,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87))),
                    selected: isSelected,
                    selectedColor: AuroraTheme.primaryBlue,
                    backgroundColor:
                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    onSelected: isAlreadyEdited
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _selectedBadges.add(badge);
                              } else {
                                _selectedBadges.remove(badge);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Comment text area
              TextField(
                controller: _commentController,
                enabled: !isAlreadyEdited,
                maxLines: 2,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'اكتب كلمة شكر أو ملاحظة للكابتن (اختياري)...',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0x5511192E) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        loc.translate('cancel'),
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ),
                  if (!isAlreadyEdited) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuroraButton(
                        text: widget.order.isReviewed ? 'حفظ التعديل' : loc.translate('submitRating'),
                        isLoading: _isSubmitting,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
