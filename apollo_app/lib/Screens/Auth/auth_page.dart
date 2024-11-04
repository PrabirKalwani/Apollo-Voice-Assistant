import 'package:apollo_app/Screens/Auth/LoginOrRegister.dart';
import 'package:apollo_app/Screens/UserLogic/Home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<bool> hasToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Token found: $token'); // Debug log
    return token != null; // Check for existing token
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: hasToken(), // Check for token
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Waiting for token check...'); // Debug log
            return Center(child: CircularProgressIndicator()); // Loading state
          } else if (snapshot.hasError) {
            print('Error occurred: ${snapshot.error}'); // Log error
            return Center(
                child: Text('An error occurred')); // Display error message
          } else if (snapshot.hasData && snapshot.data!) {
            print('Token exists, navigating to HomePage'); // Debug log
            return const HomePage(); // Token exists
          } else {
            print('No token found, navigating to Login/Register'); // Debug log
            return const LoginOrRegisterPage(); // No token found
          }
        },
      ),
    );
  }
}
