import "package:apollo_app/Components/button.dart";
import "package:apollo_app/Components/textfield.dart";
import 'package:apollo_app/Screens/Auth/login_page.dart';
import 'package:apollo_app/Screens/UserLogic/Home.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class RegisterPage extends StatefulWidget {
  final Function? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: color,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> signUserUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      showToast("Passwords don't match", Colors.red);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog manually
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      var response = await http.post(
        Uri.parse('http://13.61.37.132:6969/api/register'), // Updated endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      // Close the loading dialog before further processing
      if (mounted) {
        Navigator.pop(context); // Close the loading dialog
      }

      // Check if the status code indicates success
      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        // Check for the specific message in the response
        if (jsonResponse['message'] ==
            "Verification email sent! User created successfully!") {
          showToast("Registration successful! Verification email sent.",
              Colors.green);

          // Delay navigation to allow the lifecycle to complete
          await Future.delayed(Duration(seconds: 1)); // Optional delay

          // Check if the widget is still mounted before navigating
          if (mounted) {
            // Use the rootNavigator for navigation to the SignInPage
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => LoginPage(
                        onTap: null,
                      )), // Navigate to SignInPage
              (route) => true, // Removes all previous routes
            );
          }
        } else {
          showToast("Registration failed. Please try again.", Colors.red);
        }
      } else {
        // Handle non-success status codes
        showToast(
            "Error: ${response.statusCode} - ${response.body}", Colors.red);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close the loading dialog
      }
      showToast("An error occurred: ${e.toString()}", Colors.red);
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
                const SizedBox(
                  height: 50,
                ),
                Image.asset(
                  'lib/assets/logos/gemini_logo.png',
                  width: 75,
                  height: 75,
                ),
                const SizedBox(
                  height: 50,
                ),
                Text(
                  "Let's create an account for you!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                MyTextField(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyButton(
                  onTap: signUserUp,
                  text: 'Sign Up',
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already a member?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap as void Function()?,
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        )));
  }
}
