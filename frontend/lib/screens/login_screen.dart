import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Definicja kolorów bazujących na analizie dostarczonego interfejsu
  final Color _backgroundColor = const Color(0xFF161521);
  final Color _inputColor = const Color(0xFF4A464B);
  final Color _textColor = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Adres email i hasło nie mogą być puste.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Uwierzytelnienie w Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("Błąd pobierania danych użytkownika z Firebase.");
      }

      // 2. Pobranie tokenu JWT
      final String? token = await user.getIdToken();
      if (token == null) {
        throw Exception("Nie udało się wygenerować tokenu autoryzacyjnego.");
      }

      // 3. Komunikacja z backendem FastAPI (Konfiguracja dla Windows 11)
      // W środowisku uruchomieniowym Windows 11 (Desktop) adres to localhost.
      final Uri apiUri = Uri.parse('http://10.0.2.2:8000/api/login');

      final http.Response response = await http.post(
        apiUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 4. Analiza odpowiedzi z serwera
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _navigateToSuccessScreen(responseData['wiadomosc'] ?? "Witaj!");
      } else if (response.statusCode == 404) {
        _showErrorSnackBar("Konto zweryfikowane, brak rekordu w bazie danych.");
        // Tutaj powinna nastąpić nawigacja do ekranu dokończenia rejestracji
      } else {
        _showErrorSnackBar("Błąd serwera: ${response.statusCode}");
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    } catch (e) {
      _showErrorSnackBar("Wystąpił nieoczekiwany błąd: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    String errorMessage = "Wystąpił błąd autoryzacji.";
    if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
      errorMessage = "Nieprawidłowy adres email lub hasło.";
    } else if (e.code == 'invalid-email') {
      errorMessage = "Niepoprawny format adresu email.";
    }
    _showErrorSnackBar(errorMessage);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  void _navigateToSuccessScreen(String welcomeMessage) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _backgroundColor,
          body: Center(
            child: Text(
              welcomeMessage,
              style: TextStyle(color: _textColor, fontSize: 24, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Miejsce na logo
                Container(
                  height: 80,
                  width: 140,
                  margin: const EdgeInsets.only(bottom: 60.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                
                // Pole Adres email
                _buildLabel("Adres email:"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                
                // Pole Hasło
                _buildLabel("Hasło:"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 48),
                
                // Przycisk logowania
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _inputColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            "Zaloguj się",
                            style: TextStyle(
                              color: _textColor,
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Przycisk Nie mam konta
                _buildSecondaryButton("Nie mam konta", () {
                  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const RegistrationScreen(),
    ),
  );
                }),
                const SizedBox(height: 16),
                
                // Przycisk Przypomnij hasło
                _buildSecondaryButton("Przypomnij hasło", () {
                  // Logika resetowania hasła
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _textColor,
        fontFamily: 'monospace',
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool obscureText,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textColor, fontFamily: 'monospace'),
      decoration: InputDecoration(
        filled: true,
        fillColor: _inputColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: _inputColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _textColor,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}