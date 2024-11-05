import 'package:apollo_app/Screens/UserLogic/audio.dart';
import 'package:apollo_app/Screens/UserLogic/chat.dart';
import 'package:apollo_app/Screens/UserLogic/profile.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    AudioPage(),
    Chat(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apollo Voice Assistant',
      home: Scaffold(
        backgroundColor:
            theme.colorScheme.background, // Use the theme background color
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
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.voice_chat,
                  color: isDarkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme
                          .secondary), // Use primary or secondary color based on theme
              label: "Voice",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat,
                  color: isDarkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme
                          .secondary), // Use primary or secondary color based on theme
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person,
                  color: isDarkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme
                          .secondary), // Use primary or secondary color based on theme
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
