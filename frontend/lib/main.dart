import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Plik wygenerowany wcześniej przez FlutterFire CLI
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymApp',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'monospace',
      ),
      home: const LoginScreen(),
    );
  }
}