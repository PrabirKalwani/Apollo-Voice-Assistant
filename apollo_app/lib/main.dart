import 'package:apollo_app/firebase_options.dart';
import 'package:apollo_app/project/routes/app_route_config.dart';
import 'package:apollo_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:apollo_app/Screens/UserLogic/audio.dart';
import 'package:apollo_app/Screens/UserLogic/chat.dart';
import 'package:apollo_app/Screens/UserLogic/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routeInformationParser: MyAppRouter().router.routeInformationParser,
      routerDelegate: MyAppRouter().router.routerDelegate,
      theme: lightMode,
      darkTheme: darkMode,
    );
  }
}
