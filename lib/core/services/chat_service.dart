import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'driver' or 'customer'
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? const Uuid().v4(),
        orderId: json['order_id']?.toString() ?? '',
        senderId: json['sender_id']?.toString() ?? '',
        senderName: json['sender_name']?.toString() ?? '',
        senderRole: json['sender_role']?.toString() ?? 'customer',
        text: json['text']?.toString() ?? '',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
        isRead: json['is_read'] == true,
      );
}

class ChatService {
  static final SupabaseService _supabase = SupabaseService();

  static String _chatKey(String orderId) => 'chat_order_$orderId';

  /// Fetch all messages for an order
  static Future<List<ChatMessage>> getMessages(String orderId) async {
    try {
      final res = await _supabase.client
          .from('app_settings')
          .select('value')
          .eq('key', _chatKey(orderId))
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        final val = res.first['value'];
        if (val is Map && val['messages'] is List) {
          final list = (val['messages'] as List)
              .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
    }
    return [];
  }

  /// Send message
  static Future<bool> sendMessage({
    required String orderId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    try {
      final currentList = await getMessages(orderId);
      final newMsg = ChatMessage(
        id: const Uuid().v4(),
        orderId: orderId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      currentList.add(newMsg);

      await _supabase.client.from('app_settings').upsert({
        'key': _chatKey(orderId),
        'value': {
          'order_id': orderId,
          'last_message': text.trim(),
          'last_sender_id': senderId,
          'last_sender_name': senderName,
          'last_sender_role': senderRole,
          'updated_at': DateTime.now().toIso8601String(),
          'messages': currentList.map((m) => m.toJson()).toList(),
        },
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      return false;
    }
  }

  /// Mark all messages as read for this user
  static Future<void> markAsRead(String orderId, String currentUserId) async {
    try {
      final currentList = await getMessages(orderId);
      bool hasUnread = false;

      final updated = currentList.map((m) {
        if (m.senderId != currentUserId && !m.isRead) {
          hasUnread = true;
          return ChatMessage(
            id: m.id,
            orderId: m.orderId,
            senderId: m.senderId,
            senderName: m.senderName,
            senderRole: m.senderRole,
            text: m.text,
            timestamp: m.timestamp,
            isRead: true,
          );
        }
        return m;
      }).toList();

      if (hasUnread) {
        await _supabase.client.from('app_settings').upsert({
          'key': _chatKey(orderId),
          'value': {
            'order_id': orderId,
            'updated_at': DateTime.now().toIso8601String(),
            'messages': updated.map((m) => m.toJson()).toList(),
          },
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }
}
