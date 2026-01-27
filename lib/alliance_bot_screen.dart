import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllianceBotScreen extends StatefulWidget {
  final VoidCallback onClose;

  const AllianceBotScreen({
    super.key,
    required this.onClose,
  });

  @override
  State<AllianceBotScreen> createState() => _AllianceBotScreenState();
}

class _AllianceBotScreenState extends State<AllianceBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  static const String _apiUrl = 'https://api.pmk.codes/chat';

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: 'Hi! 👋 I\'m Alliance Bot. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to UI
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

    debugPrint('🚀 [CHATBOT] Sending message: "$message"');
    debugPrint('🔗 [CHATBOT] API URL: $_apiUrl');

    try {
      // Call your custom API at https://api.pmk.codes/chat
      // Now sending: questions, query, and message
      final uri = Uri.parse(_apiUrl);
      final requestBody = jsonEncode({
        'questions': message,      
        'query': message,          
        'message': message,         
      });

      debugPrint('📤 [CHATBOT] Request body: $requestBody');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - API not responding within 30 seconds');
        },
      );

      debugPrint('📥 [CHATBOT] Response status code: ${response.statusCode}');
      debugPrint('📥 [CHATBOT] Response headers: ${response.headers}');
      debugPrint('📥 [CHATBOT] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          debugPrint('✅ [CHATBOT] JSON decoded successfully: $jsonResponse');

          // Handle different possible response formats from your API
          final botReply = jsonResponse['reply'] ?? 
                          jsonResponse['message'] ?? 
                          jsonResponse['response'] ??
                          jsonResponse['text'] ??
                          jsonResponse['data'] ??
                          jsonResponse['answer'] ??
                          'Sorry, I couldn\'t process that.';

          debugPrint('💬 [CHATBOT] Bot reply: $botReply');

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
          }
        } catch (e) {
          debugPrint('❌ [CHATBOT] JSON decode error: $e');
          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  text: 'Error: Invalid response format from API',
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
              _isLoading = false;
            });
          }
        }
      } else {
        debugPrint('❌ [CHATBOT] HTTP Error ${response.statusCode}: ${response.body}');
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: 'Error: Server error (${response.statusCode}) - ${response.reasonPhrase}',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [CHATBOT] Network/Request error: $e');
      debugPrint('❌ [CHATBOT] Error type: ${e.runtimeType}');
      
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error: Network error - ${e.toString()}',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Alliance Bot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.blue.shade600 : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      softWrap: true,
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Alliance Bot is typing...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade700),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (value) {
                      if (!_isLoading) {
                        _sendMessage(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          _sendMessage(_messageController.text);
                        },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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