import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apollo_app/Screens/Auth/login_page.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AudioPage extends StatefulWidget {
  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isGenerating = false;
  String? _filePath;
  List<ChatMessage> _messages = [];
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final bool isPermissionGranted = await _recorder.hasPermission();
    if (!isPermissionGranted) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _filePath = '${directory.path}/$fileName';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _recorder.start(config, path: _filePath!);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isGenerating = true;
      _messages.add(ChatMessage(text: "Your audio message", isUser: true));
    });
    await _uploadRecording();
  }

  Future<void> _uploadRecording() async {
    if (_filePath == null) return;
    // For deployment use this
    final uri = Uri.parse('http://13.61.37.132:5000/generate_output');
    // for testing use this
    // final uri = Uri.parse('http://127.0.0.1:1234/generate_output');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        _filePath!,
        contentType: MediaType('audio', 'm4a'),
      ));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = jsonDecode(responseBody);

        final result = responseJson['result'] as String;
        setState(() {
          _isGenerating = false;
          _messages.add(ChatMessage(text: result, isUser: false));
        });
        _scrollToBottom();
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        setState(() {
          _isGenerating = false;
        });
      }
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onTap: () {
            // Define what happens when onTap is called, or leave it empty
          },
        ),
      ),
    );
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
              _buildAudioControls(),
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
          // Text(
          //   "Apollo",
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 18,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
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

  Widget _buildAudioControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isRecording ? 'Recording...' : 'Tap microphone to start',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.blue,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 28,
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
