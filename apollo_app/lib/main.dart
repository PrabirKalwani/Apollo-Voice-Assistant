import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'dart:convert'; // For json decoding

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder and Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioPage(),
    );
  }
}

class AudioPage extends StatefulWidget {
  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _filePath;
  double _currentPosition = 0;
  double _totalDuration = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _showResult(String result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Server Response'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(result),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadRecording() async {
    if (_filePath == null) return;

    final uri = Uri.parse('http://127.0.0.1:5000/generate_output');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        _filePath!,
        contentType: MediaType('audio', 'm4a'), // Adjust if needed
      ));

    try {
      final response = await request.send();

      // Handle response
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = jsonDecode(responseBody);

        final result = responseJson['result'] as String;
        _showResult(result);
      } else {
        print('Upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
    }
  }

  Future<void> _startRecording() async {
    final bool isPermissionGranted = await _recorder.hasPermission();
    if (!isPermissionGranted) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    // Generate a unique file name using the current timestamp
    String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _filePath = '${directory.path}/$fileName';

    // Define the configuration for the recording
    const config = RecordConfig(
      // Specify the format, encoder, sample rate, etc., as needed
      encoder: AudioEncoder.aacLc, // For example, using AAC codec
      sampleRate: 44100, // Sample rate
      bitRate: 128000, // Bit rate
    );

    // Start recording to file with the specified configuration
    await _recorder.start(config, path: _filePath!);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playRecording() async {
    if (_filePath != null) {
      await _audioPlayer.setFilePath(_filePath!);
      _totalDuration = _audioPlayer.duration?.inSeconds.toDouble() ?? 0;
      _audioPlayer.play();

      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _currentPosition = position.inSeconds.toDouble();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apollo Voice Assistant'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isRecording ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? null : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Record'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: !_isRecording ? _playRecording : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Play'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _filePath != null ? _uploadRecording : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Upload'),
            ),
            Slider(
              value: _currentPosition,
              max: _totalDuration,
              onChanged: (value) {
                setState(() {
                  _currentPosition = value;
                });
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
