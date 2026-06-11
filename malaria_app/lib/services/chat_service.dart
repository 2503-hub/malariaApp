import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import '../models/chat_message.dart';

class ChatService {
  static const _storageKey = 'chat_history_v1';

  static Future<List<ChatMessage>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final List<dynamic> arr = jsonDecode(raw) as List<dynamic>;
    return arr.map((e) {
      final map = e as Map<String, dynamic>;
      return ChatMessage(
        text: map['text'] as String? ?? '',
        sender: (map['sender'] as String? ?? 'user') == 'user'
            ? ChatMessageSender.user
            : ChatMessageSender.bot,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    }).toList();
  }

  static Future<void> saveHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final arr = messages.map((m) => {
          'text': m.text,
          'sender': m.isUser ? 'user' : 'bot',
          'timestamp': m.timestamp.toUtc().toIso8601String(),
        }).toList();

    await prefs.setString(_storageKey, jsonEncode(arr));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<ChatResponse> sendMessage(
    String message, {
    List<ChatMessage> history = const [],
  }) async {
    return AIService.chat(message, history: history);
  }
}
