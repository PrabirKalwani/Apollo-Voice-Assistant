import 'package:flutter/material.dart';
import 'package:apollo_app/pages/UserLogic/audio.dart';
import 'package:apollo_app/pages/UserLogic/chat.dart';
import 'package:apollo_app/pages/UserLogic/profile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    AudioPage(),
    Chat(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apollo Voice Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Apollo Voice Assistant'),
          elevation: 0,
        ),
        body: Center(
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          currentIndex: _currentIndex,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.voice_chat), label: "Voice"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
