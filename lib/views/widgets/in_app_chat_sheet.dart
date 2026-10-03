import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/services/chat_service.dart';
import '../../core/theme/aurora_theme.dart';
import '../../models/ride_order.dart';

class InAppChatSheet extends StatefulWidget {
  final RideOrder order;
  final String currentUserId;
  final String currentUserName;
  final bool isDriver;

  const InAppChatSheet({
    super.key,
    required this.order,
    required this.currentUserId,
    required this.currentUserName,
    required this.isDriver,
  });

  static Future<void> show(
    BuildContext context, {
    required RideOrder order,
    required String currentUserId,
    required String currentUserName,
    required bool isDriver,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InAppChatSheet(
        order: order,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        isDriver: isDriver,
      ),
    );
  }

  @override
  State<InAppChatSheet> createState() => _InAppChatSheetState();
}

class _InAppChatSheetState extends State<InAppChatSheet> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      _pollMessages();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final list = await ChatService.getMessages(widget.order.id);
    if (mounted) {
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom();
      ChatService.markAsRead(widget.order.id, widget.currentUserId);
    }
  }

  Future<void> _pollMessages() async {
    final list = await ChatService.getMessages(widget.order.id);
    if (!mounted) return;
    if (list.length != _messages.length ||
        (list.isNotEmpty && _messages.isNotEmpty && list.last.id != _messages.last.id)) {
      setState(() {
        _messages = list;
      });
      _scrollToBottom();
      ChatService.markAsRead(widget.order.id, widget.currentUserId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (quickText == null) {
      _msgController.clear();
    }
    setState(() => _isSending = true);

    final success = await ChatService.sendMessage(
      orderId: widget.order.id,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      senderRole: widget.isDriver ? 'driver' : 'customer',
      text: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _loadMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherPartyName = widget.isDriver
        ? (widget.order.customerName ?? 'الزبون')
        : (widget.order.driverName ?? 'كابتن ميسان');
    final otherPartyRole = widget.isDriver ? 'صاحب الطلب' : (widget.order.vehicleInfo ?? 'كابتن معتمد');

    final quickReplies = widget.isDriver
        ? [
            'وصلت لموقعك 📍',
            'أنا في الطريق إليك 🚗',
            'دقيقتين وأكون عندك ⏳',
            'أمام الباب الرئيسي 🏠',
            'تمام، بالانتظار 👍',
          ]
        : [
            'أنا بانتظارك بالخارج 📍',
            'قادم إليك الآن 🚶‍♂️',
            'أمام المنزل بالضبط 🏠',
            'تمام كابتن، شكراً لك 👍',
          ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: widget.isDriver
                        ? const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)])
                        : AuroraTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isDriver ? Icons.person_rounded : Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherPartyName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$otherPartyRole • محادثة الرحلة',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد رسائل بعد\nيمكنك بدء المحادثة مع $otherPartyName',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isMe = msg.senderId == widget.currentUserId;
                          final timeStr = intl.DateFormat('hh:mm a').format(msg.timestamp);

                          return Align(
                            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.76,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                      )
                                    : null,
                                color: isMe
                                    ? null
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                  bottomRight: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Quick replies
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: quickReplies.length,
              itemBuilder: (ctx, i) {
                final reply = quickReplies[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    label: Text(
                      reply,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    onPressed: () => _sendMessage(reply),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: TextField(
                        controller: _msgController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالة لـ $otherPartyName...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AuroraTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
