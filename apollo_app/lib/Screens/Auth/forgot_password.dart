// ignore_for_file: deprecated_member_use

import 'package:apollo_app/Components/button.dart';
import 'package:apollo_app/Components/textfield.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'package:fluttertoast/fluttertoast.dart'; // Import FlutterToast
import 'dart:convert'; // Import for jsonEncode

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    String email = _emailController.text;

    // Make sure the email is not empty
    if (email.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your email',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final Uri uri = Uri.parse(
        'http://localhost:8080/api/reset-password'); // Updated with your backend URL

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      // Check the status code and response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] ==
            "Password reset email sent successfully!") {
          Fluttertoast.showToast(
            msg: responseData['message'], // Display success message
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to send reset email', // Display failure message
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to send reset email', // Display failure message
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      // Handle any errors that occurred during the network request
      Fluttertoast.showToast(
        msg: 'Error: $e', // Display error message
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Row(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 70, top: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          children: [
            Image.asset(
              'lib/assets/logos/gemini_logo.png',
              width: 75,
              height: 75,
            ),
            const SizedBox(
              height: 25,
            ),
            Text(
              "Reset Your Password",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "We Will Send You An Email \n To Reset Your Password",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 50),
            MyTextField(
              controller: _emailController,
              hintText: "Your Registered Email",
              obscureText: false,
            ),
            const SizedBox(height: 20),
            MyButton(
              text: 'Reset',
              onTap: _resetPassword,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Facing Issues?",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onLongPress: () {
                    // You can add your own functionality here or remove the gesture detector
                  },
                  child: const Text(
                    "Support",
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
    );
  }
}
