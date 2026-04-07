import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Scenariusz 1: Oczekiwanie na odpowiedź z serwerów Firebase (np. podczas słabego połączenia)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF161521),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Scenariusz 2: Użytkownik posiada aktywną sesję autoryzacyjną
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Scenariusz 3: Brak aktywnej sesji (użytkownik niezalogowany lub sesja wygasła)
        return const LoginScreen();
      },
    );
  }
}