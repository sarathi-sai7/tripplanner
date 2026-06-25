import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get _kApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
const String _kModel = 'llama-3.1-8b-instant';
const String _kApiUrl = 'https://api.groq.com/openai/v1/chat/completions';

const String _kSystemPrompt =
    'You are Voyage, a friendly and knowledgeable travel assistant embedded in a Trip Planner app. '
    'You help users plan trips, suggest destinations, recommend hotels, estimate budgets, '
    'advise on local food, culture, and transport, and answer any travel-related questions. '
    'Keep responses concise (2–4 sentences unless more detail is needed), warm, and practical. '
    'Focus especially on Indian destinations and travel.';

// ── Data model ───────────────────────────────────────────────────

class _Message {
  final String text;
  final bool isUser;
  final DateTime time;

  const _Message({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// ── Screen ───────────────────────────────────────────────────────

class AIAssistant extends StatefulWidget {
  const AIAssistant({super.key});

  @override
  State<AIAssistant> createState() => _AIAssistantState();
}

class _AIAssistantState extends State<AIAssistant>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_Message> _messages = [];

  // Groq/OpenAI format: { "role": "user"|"assistant", "content": "..." }
  final List<Map<String, dynamic>> _apiHistory = [];

  bool _isLoading = false;

  final List<String> _suggestions = [
    "Best places to visit in Kerala 🌴",
    "Budget trip to Rajasthan 💰",
    "What to pack for Manali in winter ❄️",
    "Top street foods in Tamil Nadu 🍛",
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    if (_kApiKey.isEmpty) {
      _showError("API key not found. Add GROQ_API_KEY to your .env file.");
      return;
    }

    _inputController.clear();

    setState(() {
      _messages.add(_Message(text: query, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    // Append user turn to history
    _apiHistory.add({"role": "user", "content": query});

    try {
      final response = await http.post(
        Uri.parse(_kApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_kApiKey',
        },
        body: jsonEncode({
          "model": _kModel,
          "messages": [
            {"role": "system", "content": _kSystemPrompt},
            ..._apiHistory,
          ],
          "max_tokens": 512,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;

        // Append assistant reply to history for multi-turn context
        _apiHistory.add({"role": "assistant", "content": reply});

        setState(() {
          _messages
              .add(_Message(text: reply, isUser: false, time: DateTime.now()));
        });
      } else {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? 'Unknown error';
        _showError("API error ${response.statusCode}: $msg");
        _apiHistory.removeLast();
      }
    } catch (e) {
      _showError("Network error. Check your connection.");
      _apiHistory.removeLast();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _showError(String msg) {
    setState(() {
      _messages
          .add(_Message(text: "⚠️ $msg", isUser: false, time: DateTime.now()));
    });
  }

  String _formatTime(DateTime t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildChatList(),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 8,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.travel_explore,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Voyage Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Online · Groq AI",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                color: Colors.white70, size: 22),
            tooltip: "Clear chat",
            onPressed: _messages.isEmpty
                ? null
                : () => setState(() {
                      _messages.clear();
                      _apiHistory.clear();
                    }),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF26C6DA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.travel_explore,
                color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            "Hi! I'm Voyage 👋",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your personal travel assistant.\nAsk me anything about your next trip!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black45, height: 1.6),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Try asking:",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _suggestions
                .map((s) => GestureDetector(
                      onTap: () => _sendMessage(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Colors.teal,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Chat list ──────────────────────────────────────────────────

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_Message msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF26C6DA)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.travel_explore,
                  color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.teal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.time),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF26C6DA)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.travel_explore,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Ask about destinations, hotels, tips...",
                  hintStyle:
                      TextStyle(color: Colors.black38, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF26C6DA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing dots animation ────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = ((_anim.value * 3) - i).clamp(0.0, 1.0);
            final scale = 0.6 +
                0.4 *
                    (1 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}