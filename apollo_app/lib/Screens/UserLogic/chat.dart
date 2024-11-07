import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    final userMessage = _textController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isGenerating = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://13.61.37.132:5000/generate_output_text'),

        // Uri.parse('http://localhost:1234/generate_output_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': userMessage}),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final result = responseJson['response'] as String;
        setState(() {
          _isGenerating = false;
          _messages.add(ChatMessage(text: result, isUser: false));
        });
        _scrollToBottom();
      } else {
        print('Request failed with status code: ${response.statusCode}');
        setState(() {
          _isGenerating = false;
          _messages.add(ChatMessage(
              text: "Failed to get response from server.", isUser: false));
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _isGenerating = false;
        _messages.add(ChatMessage(
            text: "An error occurred while sending the message.",
            isUser: false));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildMessageList(),
              ),
              if (_isGenerating) _buildGeneratingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Space out the items
        children: [
          // Logo on the left
          Image.asset(
            'lib/assets/logos/logo.png',
            height: 50,
          ),
          // Greeting text in the middle
          Text(
            "Chat Client",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemBuilder: (_, int index) => _messages[index],
      itemCount: _messages.length,
    );
  }

  Widget _buildGeneratingIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(width: 16),
          Text(
            'Generating response...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar('Bot'),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'You' : 'Bot',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  isUser
                      ? Text(
                          text,
                          style: TextStyle(color: Colors.white),
                        )
                      : MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 16, color: Colors.white),
                            strong: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
            ),
          ),
          if (isUser) _buildAvatar('You'),
        ],
      ),
    );
  }

  Widget _buildAvatar(String label) {
    return Container(
      margin: EdgeInsets.only(right: 16, left: 16),
      child: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          label[0],
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
