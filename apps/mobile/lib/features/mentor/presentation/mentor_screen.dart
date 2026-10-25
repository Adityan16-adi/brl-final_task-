import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/errors/error_message_helper.dart';
import 'package:mobile/core/providers/network_providers.dart';
import 'package:mobile/core/theme/clay_theme.dart';

final mentorSessionProvider = Provider<String>((ref) {
  return 'mobile-${DateTime.now().microsecondsSinceEpoch}';
});

class MentorMessage {
  const MentorMessage({
    required this.text,
    required this.isUser,
    this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime? timestamp;
}

class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key});

  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<MentorMessage> _messages = [];
  bool _sending = false;
  String? _error;
  String? _lastFailedPrompt;

  @override
  void initState() {
    super.initState();
    _warmUpMentor();
  }

  /// Fire a silent warm-up GET request to the backend mentor health proxy
  /// so the hosted service wakes up before the user finishes typing.
  void _warmUpMentor() {
    try {
      final dio = ref.read(coreDioProvider);
      dio.get<dynamic>(
        '/api/mentor/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 10),
        ),
      ).catchError((_) {
        // Silent catch: failures during warm-up must not disrupt the UI
        return Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/mentor/health'),
        );
      });
    } catch (_) {
      // Ignored
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? prefilledText]) async {
    final text = (prefilledText ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    if (prefilledText == null) {
      _controller.clear();
    }

    // Immediately add user message to chat list
    setState(() {
      _messages.add(
        MentorMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _sending = true;
      _error = null;
      _lastFailedPrompt = null;
    });
    _scrollToBottom();

    try {
      final dio = ref.read(coreDioProvider);
      final sessionId = ref.read(mentorSessionProvider);

      final response = await dio.post<Map<String, dynamic>>(
        '/api/mentor/chat',
        data: {'session_id': sessionId, 'message': text},
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final reply = response.data?['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) {
        throw const FormatException('The mentor service returned an empty reply.');
      }

      if (!mounted) return;
      setState(() {
        _messages.add(
          MentorMessage(text: reply, isUser: false, timestamp: DateTime.now()),
        );
        _error = null;
        _lastFailedPrompt = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _lastFailedPrompt = text;
      String message;
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.response?.statusCode == 504 ||
            e.response?.statusCode == 502) {
          message = 'AI is waking up, please wait a moment...';
        } else if (e.response?.statusCode == 429) {
          message = 'AI rate limit reached, please try again in a few moments.';
        } else {
          message = ErrorMessageHelper.format(
            e,
            fallback: 'The AI Mentor is currently unavailable. Tap to retry.',
          );
        }
      } else {
        message = ErrorMessageHelper.format(
          e,
          fallback: 'The AI Mentor is currently unavailable. Tap to retry.',
        );
      }

      setState(() {
        _error = message;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resetChat() async {
    if (_sending) return;

    try {
      final dio = ref.read(coreDioProvider);
      final sessionId = ref.read(mentorSessionProvider);
      await dio.post<void>(
        '/api/mentor/reset',
        queryParameters: {'session_id': sessionId},
      );
    } catch (_) {
      // Local reset fallback
    }

    if (!mounted) return;
    setState(() {
      _messages.clear();
      _error = null;
      _lastFailedPrompt = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation reset successfully.'),
        backgroundColor: ClayTokens.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ClayTokens.brightBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: ClayTokens.brightBlue,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Mentor',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  'Interactive Study Companion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset conversation',
            onPressed: _sending ? null : _resetChat,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildWelcomeState(context, isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _ThreeDotsTypingIndicator(isDark: isDark);
                          }
                          final message = _messages[index];
                          return _buildMessageBubble(context, message, isDark);
                        },
                      ),
              ),

              // Timeout & Error retry card
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      if (_lastFailedPrompt != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _sending ? null : () => _sendMessage(_lastFailedPrompt),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Modern Flat Input Area
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ask a question or explain a concept...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _sending ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)) : ClayTokens.brightBlue,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: _sending ? null : () => _sendMessage(),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.send_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
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
  }

  Widget _buildWelcomeState(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ClayTokens.brightBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 32,
                color: ClayTokens.brightBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What would you like to learn today?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask questions about homework, math concepts, or study plans.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Suggested Topics
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Topics',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          for (final prompt in [
            'Explain Newton\'s Laws of Motion with examples',
            'Break down Calculus derivatives step-by-step',
            'Create a 5-day study plan for exams',
            'How to structure an academic research report',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: _sending ? null : () => _sendMessage(prompt),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: ClayTokens.brightBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prompt,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MentorMessage message,
    bool isDark,
  ) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? ClayTokens.brightBlue
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                  size: 13,
                  color: isUser ? Colors.white70 : ClayTokens.brightBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'You' : 'AI Mentor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUser ? Colors.white70 : ClayTokens.brightBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isUser ? Colors.white : (isDark ? Colors.white : ClayTokens.navy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smooth 3-dot wave typing indicator for AI Mentor
class _ThreeDotsTypingIndicator extends StatefulWidget {
  const _ThreeDotsTypingIndicator({required this.isDark});
  final bool isDark;

  @override
  State<_ThreeDotsTypingIndicator> createState() => _ThreeDotsTypingIndicatorState();
}

class _ThreeDotsTypingIndicatorState extends State<_ThreeDotsTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isDark ? Colors.white70 : ClayTokens.brightBlue;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: ClayTokens.brightBlue,
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase = (_animController.value * 2 * math.pi) - (index * 0.8);
                    final sinVal = math.sin(phase);
                    final bounce = sinVal > 0 ? sinVal * 4.0 : 0.0;
                    return Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 5,
                        bottom: bounce,
                      ),
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        color: dotColor.withValues(
                          alpha: (0.4 + ((sinVal + 1) / 2 * 0.6)).clamp(0.0, 1.0),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
