import 'package:apollo_app/Screens/UserLogic/Home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apollo_app/Components/button.dart';
import 'package:apollo_app/Components/textfield.dart';
import 'package:apollo_app/Screens/Auth/forgot_password.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Importing the fluttertoast package

class LoginPage extends StatefulWidget {
  final Function? onTap;

  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isNavigating = false; // Flag to prevent re-entrant navigation

  @override
  void initState() {
    super.initState();
    emailController.clear();
    passwordController.clear();
  }

  Future<void> signUserIn() async {
    if (_isNavigating) return; // Prevent further navigation while navigating
    _isNavigating = true; // Set the flag to true

    try {
      print('Sending login request...'); // Debug log
      var response = await http.post(
        Uri.parse('http://13.61.37.132:6969/api/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data != null && data['message'] == "User logged in successfully") {
          if (data['userCredential'] != null &&
              data['userCredential']['user'] != null &&
              data['userCredential']['user']['stsTokenManager'] != null) {
            String accessToken = data['userCredential']['user']
                ['stsTokenManager']['accessToken'];
            String refreshToken = data['userCredential']['user']
                ['stsTokenManager']['refreshToken'];
            String uid = data['userCredential']['user']['uid'];
            String email = data['userCredential']['user']['email'];

            print(
                'Login successful, token received: $accessToken'); // Debug log

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'auth_token', accessToken); // Store access token
            await prefs.setString('refresh_token', refreshToken);
            await prefs.setString('uid', uid);
            await prefs.setString('email', email);

            print(
                'Tokens and user info stored in shared preferences.'); // Debug log

            // Show success toast
            Fluttertoast.showToast(
              msg: "Login successful!",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            // Use a delay before navigation
            if (mounted) {
              await Future.delayed(Duration(milliseconds: 1000));
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => true,
              );
            }
          } else {
            Fluttertoast.showToast(
              msg: "Login failed: Invalid response structure.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: "Login failed: ${data['message']}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Login failed: ${response.body}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      print('Error occurred: $e'); // Debug log
      Fluttertoast.showToast(
        msg: "An error occurred: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      _isNavigating = false; // Reset the flag regardless of the outcome
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset(
                  'lib/assets/logos/logo.png',
                  width: 75,
                  height: 75,
                ),
                const SizedBox(height: 25),
                Text(
                  "Welcome to Apollo!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.primary,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Not a member?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap as void Function()?,
                      child: const Text(
                        "Register Now",
                        style: TextStyle(
                          color: Colors.blue,
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
