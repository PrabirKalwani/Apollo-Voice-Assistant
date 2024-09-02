import 'package:apollo_app/Screens/Auth/LoginOrRegister.dart';
import 'package:apollo_app/Screens/UserLogic/Home.dart';
import 'package:flutter/material.dart';
import "package:firebase_auth/firebase_auth.dart";

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return const HomePage();
              } else {
                return const LoginOrRegisterPage();
              }
            }));
  }
}
