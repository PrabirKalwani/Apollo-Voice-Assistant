import 'package:apollo_app/Screens/UserLogic/Home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apollo_app/Components/button.dart';
import 'package:apollo_app/Components/textfield.dart';
import 'package:apollo_app/Screens/Auth/forgot_password.dart';

class LoginPage extends StatefulWidget {
  final Function? onTap;

  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear the text fields when the login page is initialized
    emailController.clear();
    passwordController.clear();
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Center(
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        );
      },
    );
  }

  Future<void> signUserIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      print('Sending login request...'); // Debug log
      var response = await http.post(
        Uri.parse('http://127.0.0.1:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (mounted) {
        Navigator.pop(context); // Close the loading dialog
      }

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        // Parse the response
        var data = jsonDecode(response.body);
        if (data['success'] == true) {
          String token = data['token'];
          print('Login successful, token received: $token'); // Debug log

          // Store the token in shared preferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setInt('token_expiry',
              DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch);

          print('Token stored in shared preferences.'); // Debug log

          // Delay navigation to allow any transitions to complete
          await Future.delayed(Duration(seconds: 1));

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => true, // Clear the stack
              );
            });
          }
        } else {
          showErrorMessage("Login failed: ${response.body}");
        }
      } else {
        showErrorMessage("Login failed: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      print('Error occurred: $e'); // Debug log
      showErrorMessage("An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context)
          .colorScheme
          .background, // Use background color from the theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset(
                  'lib/assets/logos/gemini_logo.png',
                  width: 75,
                  height: 75,
                ),
                const SizedBox(height: 25),
                Text(
                  "Welcome to Appollo!",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .primary, // Use primary color from the theme
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .primary, // Use primary color for the button
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                MyButton(
                  text: 'Sign In',
                  onTap: signUserIn,
                ),
                const SizedBox(height: 50),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Not a member?",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary, // Use primary color for text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap as void Function()?,
                      child: const Text(
                        "Register Now",
                        style: TextStyle(
                          color: Colors
                              .blue, // Change to a color from your theme if needed
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
