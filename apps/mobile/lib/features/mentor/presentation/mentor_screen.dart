import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    setState(() {
      _messages.add(
        MentorMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _sending = true;
      _error = null;
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
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      String errMsg;
      if (e is DioException) {
        final serverMsg = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          errMsg = serverMsg;
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errMsg = 'AI Mentor request timed out. Please try again.';
        } else if (e.type == DioExceptionType.connectionError ||
            e.response == null) {
          errMsg = 'Cannot reach backend server. Please verify network connectivity.';
        } else {
          errMsg = 'AI Mentor service returned error ${e.response?.statusCode}: ${e.message}';
        }
      } else {
        errMsg = 'AI Mentor error: $e';
      }
      setState(() {
        _error = errMsg;
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
      // Local reset
    }

    if (!mounted) return;
    setState(() {
      _messages.clear();
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation reset successfully.'),
        backgroundColor: ClayTokens.deepIndigo,
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AI Mentor',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                SizedBox(width: 8),
                ClayBadge(
                  label: '24/7 ONLINE',
                  fontSize: 9,
                  backgroundColor: ClayTokens.mint,
                  textColor: ClayTokens.mintDark,
                ),
              ],
            ),
            Text(
              'Your personalized interactive study companion',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset conversation',
            onPressed: _sending ? null : _resetChat,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeState(context, isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator(isDark);
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(context, message, isDark);
                    },
                  ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.redAccent.shade100,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // Claymorphic Input Area
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ClayContainer(
                      depth: 3,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ask a question or explain a concept...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: ClayTokens.secondaryText,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClayButton(
                    onPressed: _sending ? null : () => _sendMessage(),
                    padding: const EdgeInsets.all(13),
                    borderRadius: BorderRadius.circular(ClayTokens.radiusPill),
                    depth: 5,
                    child: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: Colors.white,
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

  Widget _buildWelcomeState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayContainer(
              width: 72,
              height: 72,
              depth: 6,
              color: ClayTokens.softLavender,
              borderRadius: BorderRadius.circular(24),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 38,
                  color: ClayTokens.deepIndigo,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What would you like to master today?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Get instant homework help, step-by-step math derivations, and personalized study schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // Prompt Chips
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggested Topics:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            for (final prompt in [
              'Explain Newton\'s Laws of Motion with real examples',
              'Break down Calculus derivatives step-by-step',
              'Create a 5-day study plan for midterm exams',
              'How to structure an academic research report',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClayCard(
                  depth: 3,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onTap: _sending ? null : () => _sendMessage(prompt),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: ClayTokens.deepIndigo,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: ClayTokens.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ClayContainer(
          depth: 3,
          color: isDark ? ClayTokens.darkCard : ClayTokens.softLavender,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(18),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ClayTokens.deepIndigo,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'AI Mentor is thinking...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClayTokens.deepIndigo,
                ),
              ),
            ],
          ),
        ),
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
        margin: const EdgeInsets.only(bottom: 14),
        child: ClayContainer(
          depth: 4,
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6356F5), Color(0xFF473BB8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isUser ? (isDark ? ClayTokens.darkCard : Colors.white) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                    size: 13,
                    color: isUser ? Colors.white70 : ClayTokens.deepIndigo,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUser ? 'You' : 'AI Mentor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isUser ? Colors.white70 : ClayTokens.deepIndigo,
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
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : ClayTokens.darkInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
