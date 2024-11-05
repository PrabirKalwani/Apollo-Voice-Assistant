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

    final uri = Uri.parse('http://127.0.0.1:5000/generate_output');
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Chat',
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.onPrimary),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8.0),
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          if (_isGenerating)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 8),
                  Text('Generating response...',
                      style: TextStyle(color: theme.colorScheme.onBackground)),
                ],
              ),
            ),
          Divider(height: 1.0, color: theme.dividerColor),
          Container(
            decoration: BoxDecoration(color: theme.cardColor),
            child: _buildAudioControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isRecording ? 'Recording...' : 'Tap microphone to start',
              style: TextStyle(
                  fontSize: 16, color: theme.colorScheme.onBackground),
            ),
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                color: _isRecording
                    ? Colors.red
                    : theme.colorScheme
                        .primary), // Use theme primary color for mic icon
            onPressed: _isRecording ? _stopRecording : _startRecording,
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
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isUser
              ? Expanded(child: SizedBox())
              : Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                      child: Text('Bot',
                          style:
                              TextStyle(color: theme.colorScheme.onSurface))),
                ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(isUser ? 'You' : 'Bot',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground)),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: isUser
                      ? Text(text,
                          style:
                              TextStyle(color: theme.colorScheme.onBackground))
                      : MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onBackground),
                            strong: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
          isUser
              ? Container(
                  margin: const EdgeInsets.only(left: 16.0),
                  child: CircleAvatar(
                      child: Text('You',
                          style:
                              TextStyle(color: theme.colorScheme.onSurface))),
                )
              : Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
