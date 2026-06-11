import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../repositories/scan_history_repository.dart';
import '../models/scan_history.dart';

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  State<HealthAssistantScreen> createState() => _HealthAssistantScreenState();
}

class _HealthAssistantScreenState extends State<HealthAssistantScreen> {
  static const _quickActions = [
    'Symptoms',
    'Prevention',
    'Treatment',
    'Explain My Result',
    'About Malaria',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hello. I can answer malaria questions and explain prediction results. How can I help?',
      sender: ChatMessageSender.bot,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedHistory();
  }

  Future<void> _loadSavedHistory() async {
    final saved = await ChatService.loadHistory();
    if (saved.isNotEmpty) {
      setState(() {
        _messages.clear();
        _messages.addAll(saved);
      });
      _scrollToBottom();
    }
  }

  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickMessage]) async {
    String message = (quickMessage ?? _messageController.text).trim();

    if (quickMessage == 'Explain My Result') {
      try {
        final repo = ScanHistoryRepository();
        final scans = await repo.getScans();
        if (scans.isNotEmpty) {
          final last = scans.first;
          message = 'Please explain this analysis result: ${last.prediction} with ${last.confidence}% confidence.';
        } else {
          message = 'I recently analyzed no images. Please run an analysis first.';
        }
      } catch (_) {
        message = 'I could not access recent analysis results.';
      }
    }

    if (message.isEmpty || _isTyping) return;

    final historyBeforeSend = List<ChatMessage>.from(_messages);
    _messageController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          sender: ChatMessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await ChatService.sendMessage(
        message,
        history: historyBeforeSend,
      );
      // persist after successful response
      await ChatService.saveHistory(_messages);
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.reply,
            sender: ChatMessageSender.bot,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: _friendlyError(error),
            sender: ChatMessageSender.bot,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isTyping = false;
      });
      await ChatService.saveHistory(_messages);
      _scrollToBottom();
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('GEMINI_API_KEY')) {
      return 'The health assistant backend is running, but Gemini is not configured yet. Add GEMINI_API_KEY to backend/.env and restart the backend.';
    }

    if (message.isNotEmpty) {
      return 'Health assistant error: $message';
    }

    return 'I could not reach the health assistant service. Please make sure the backend server is running.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        actions: [
          IconButton(
            tooltip: 'Clear chat history',
            onPressed: () async {
              await ChatService.clearHistory();
              if (!mounted) return;
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text:
                        'Hello. I can answer malaria questions and explain prediction results. How can I help?',
                    sender: ChatMessageSender.bot,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFE6FFFB),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF087F7A),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.medical_services),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'General malaria information only. Seek professional care for diagnosis or treatment.',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _QuickActions(
              actions: _quickActions,
              enabled: !_isTyping,
              onSelected: _sendMessage,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingBubble();
                  }

                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _MessageInput(
              controller: _messageController,
              enabled: !_isTyping,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final List<String> actions;
  final bool enabled;
  final ValueChanged<String> onSelected;

  const _QuickActions({
    required this.actions,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];

          return ActionChip(
            avatar: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(action),
            onPressed: enabled ? () => onSelected(action) : null,
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final backgroundColor =
        isUser ? const Color(0xFF087F7A) : Colors.white;
    final textColor = isUser ? Colors.white : const Color(0xFF0F172A);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(isUser ? 8 : 2),
              bottomRight: Radius.circular(isUser ? 2 : 8),
            ),
            border: isUser
                ? null
                : Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isUser ? Colors.white70 : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: _TypingDots(),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> {
  late final Timer _timer;
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      setState(() {
        _activeDot = (_activeDot + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: index == _activeDot
                ? const Color(0xFF087F7A)
                : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => enabled ? onSend() : null,
              decoration: InputDecoration(
                hintText: 'Ask about malaria or a prediction result',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}
