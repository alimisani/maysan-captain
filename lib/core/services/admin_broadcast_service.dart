import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class AdminBroadcastService {
  static final SupabaseService _supabase = SupabaseService();

  /// Retrieve all administrative broadcast messages
  static Future<List<Map<String, dynamic>>> getBroadcasts() async {
    try {
      final res = await _supabase.client
          .from('app_settings')
          .select('value')
          .eq('key', 'admin_broadcast_messages')
          .limit(1);

      if (res.isNotEmpty && res.first['value'] != null) {
        final val = res.first['value'];
        if (val is List) {
          final list = List<Map<String, dynamic>>.from(
            val.map((item) => Map<String, dynamic>.from(item as Map)),
          );
          // Sort newest first
          list.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error getting admin broadcasts: $e');
    }
    return [];
  }

  /// Save and dispatch broadcast message to all users
  static Future<bool> sendBroadcast({
    String? id,
    required String title,
    required String body,
    bool isDraft = false,
  }) async {
    try {
      final list = await getBroadcasts();
      final now = DateTime.now().toIso8601String();
      final msgId = (id != null && id.isNotEmpty) ? id : const Uuid().v4();

      final existingIndex = list.indexWhere((m) => m['id'] == msgId);
      final newMsg = <String, dynamic>{
        'id': msgId,
        'title': title.trim(),
        'body': body.trim(),
        'created_at': existingIndex >= 0 ? (list[existingIndex]['created_at'] ?? now) : now,
        'updated_at': now,
        'sent_at': isDraft ? null : now,
        'is_sent': !isDraft,
      };

      if (existingIndex >= 0) {
        list[existingIndex] = newMsg;
      } else {
        list.insert(0, newMsg);
      }

      // Save messages array
      await _supabase.client.from('app_settings').upsert({
        'key': 'admin_broadcast_messages',
        'value': list,
        'updated_at': now,
      });

      // If active broadcast, push to latest_admin_broadcast to trigger external notifications
      if (!isDraft) {
        await _supabase.client.from('app_settings').upsert({
          'key': 'latest_admin_broadcast',
          'value': {
            'id': msgId,
            'title': title.trim(),
            'body': body.trim(),
            'sent_at': now,
          },
          'updated_at': now,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error sending admin broadcast: $e');
      return false;
    }
  }

  /// Resend an existing message to trigger notifications on all user devices again
  static Future<bool> resendBroadcast(Map<String, dynamic> msg) async {
    try {
      final msgId = msg['id']?.toString() ?? const Uuid().v4();
      final title = msg['title']?.toString() ?? '';
      final body = msg['body']?.toString() ?? '';

      return await sendBroadcast(
        id: msgId,
        title: title,
        body: body,
        isDraft: false,
      );
    } catch (e) {
      debugPrint('Error resending broadcast: $e');
      return false;
    }
  }

  /// Delete a broadcast message
  static Future<bool> deleteBroadcast(String id) async {
    try {
      final list = await getBroadcasts();
      list.removeWhere((m) => m['id'] == id);

      await _supabase.client.from('app_settings').upsert({
        'key': 'admin_broadcast_messages',
        'value': list,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error deleting broadcast: $e');
      return false;
    }
  }
}
