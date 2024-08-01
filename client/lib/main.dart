import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Audio Recorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Audio Recorder Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _filePath;
  String? _result;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initializeRecorder();
    _initializePlayer();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
  }

  Future<void> _initializePlayer() async {
    await _player!.openPlayer();
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.wav';
    await _recorder!.startRecorder(
      toFile: _filePath,
      codec: Codec.pcm16WAV,
      numChannels: 1,
    );

    // Stop recording after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (_recorder!.isRecording) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {});
  }

  Future<void> _playRecording() async {
    if (_filePath != null) {
      await _player!.startPlayer(fromURI: _filePath, codec: Codec.pcm16WAV);
    }
  }

  Future<void> _sendAudio() async {
    if (_filePath == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:5000/generate_output'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', _filePath!),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var decodedData = json.decode(responseData);
      setState(() {
        _result = decodedData['result'];
      });
    } else {
      setState(() {
        _result = 'Error: ${response.statusCode}';
      });
    }
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _player!.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_result != null)
              Text(
                'Result: $_result',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recorder!.isRecording ? null : _startRecording,
              child: const Text('Start Recording'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: !_recorder!.isRecording ? _stopRecording : null,
              child: const Text('Stop Recording'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _filePath != null ? _playRecording : null,
              child: const Text('Play Recording'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendAudio,
              child: const Text('Send Audio'),
            ),
            if (_filePath != null)
              Text(
                'File Path: $_filePath',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
