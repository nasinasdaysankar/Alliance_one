import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api.dart';

class AllianceBotScreen extends StatefulWidget {
  final VoidCallback onClose;

  const AllianceBotScreen({
    super.key,
    required this.onClose,
  });

  @override
  State<AllianceBotScreen> createState() => _AllianceBotScreenState();
}

class _AllianceBotScreenState extends State<AllianceBotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  static String get _apiUrl {
    return '${ApiConfig.baseUrl}/chat/ask';
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistory = prefs.getStringList('chat_history') ?? [];
      
      if (chatHistory.isEmpty) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Hello! 👋\n\nI\'m your Alliance ONE 2026 assistant. Ask me about events, schedules, coordinators, or registration!',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      } else {
        setState(() {
          _messages = chatHistory.map((jsonStr) {
            final json = jsonDecode(jsonStr);
            return ChatMessage(
              text: json['text'],
              isUser: json['isUser'],
              timestamp: DateTime.parse(json['timestamp']),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistory = _messages.map((msg) {
        return jsonEncode({
          'text': msg.text,
          'isUser': msg.isUser,
          'timestamp': msg.timestamp.toIso8601String(),
        });
      }).toList();
      await prefs.setStringList('chat_history', chatHistory);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() {
      _messages = [
        ChatMessage(
          text: 'Hello! 👋\n\nI\'m your Alliance ONE 2026 assistant. Ask me about events, schedules, coordinators, or registration!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    });
    await _saveChatHistory();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();
    await _saveChatHistory();

    try {
      final uri = Uri.parse(_apiUrl);
      final requestBody = jsonEncode({'question': message});

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final botReply = jsonResponse['answer'] ??
            jsonResponse['response'] ??
            'I couldn\'t understand that. Please try again.';

        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: botReply.toString(),
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          await _saveChatHistory();
        }
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: '⚠️ Connection Error\n\nPlease check your internet and try again.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        await _saveChatHistory();
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _sheetController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.75, 0.95],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F0F23),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  
                  _buildPremiumHeader(),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingIndicator();
                          }
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
                    ),
                  ),
                  
                  _buildPremiumInputArea(bottomInset),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.2),
            const Color(0xFF9B59B6).withOpacity(0.15),
            const Color(0xFF3498DB).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          // University Logo Avatar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(
                        0.4 + (_pulseController.value * 0.3),
                      ),
                      blurRadius: 20 + (_pulseController.value * 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF9B59B6).withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/alliance_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE0E0E0)],
                      ).createShader(bounds),
                      child: const Text(
                        'Alliance AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D9A5), Color(0xFF00B894)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9A5).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00D9A5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D9A5).withOpacity(
                                  0.5 + (_pulseController.value * 0.5),
                                ),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Always ready to help',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.refresh_rounded,
                onTap: _clearChatHistory,
                tooltip: 'Clear chat',
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.close_rounded,
                onTap: widget.onClose,
                tooltip: 'Close',
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: isPrimary ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(isPrimary ? 0.25 : 0.1),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/images/alliance_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6C63FF),
                          Color(0xFF8B5CF6),
                          Color(0xFF9B59B6),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2D3748).withOpacity(0.9),
                          const Color(0xFF1A202C).withOpacity(0.9),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 22),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(isUser ? 0.2 : 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF6C63FF).withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D3748).withOpacity(0.9),
              const Color(0xFF1A202C).withOpacity(0.9),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thinking',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (index) => _buildAnimatedDot(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final delay = index * 0.3;
        final value = ((_pulseController.value + delay) % 1.0);
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF6C63FF).withOpacity(0.4 + (value * 0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(value * 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumInputArea(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.0),
            const Color(0xFF1A1A2E).withOpacity(0.95),
            const Color(0xFF16213E),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D3748).withOpacity(0.8),
              const Color(0xFF1A202C).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, -5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji/Attachment button
            Container(
              margin: const EdgeInsets.only(left: 6),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.emoji_emotions_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 22,
              ),
            ),
            
            // Text field
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            
            // Send button
            Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendMessage(_messageController.text),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF9B59B6),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}