import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final Color _backgroundColor = const Color(0xFF161521);
  final Color _inputColor = const Color(0xFF4A464B);
  final Color _textColor = Colors.white;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Wszystkie pola są wymagane.");
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar("Hasła nie są identyczne.");
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar("Hasło musi zawierać minimum 6 znaków.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Utworzenie konta w Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) throw Exception("Błąd tworzenia użytkownika w Firebase.");

      // 2. Pobranie tokenu autoryzacyjnego
      final String? token = await user.getIdToken();
      if (token == null) throw Exception("Błąd generowania tokenu.");

      // 3. Rejestracja w lokalnej bazie PostgreSQL poprzez FastAPI
      final Uri apiUri = Uri.parse('http://10.0.2.2:8000/api/register');
      final http.Response response = await http.post(
        apiUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nazwa_uzytkownika': username,
        }),
      );

      // 4. Analiza odpowiedzi serwera i wdrożenie mechanizmu kompensacyjnego
      if (response.statusCode == 201) {
        //_navigateToSuccessScreen("Konto utworzone. Witaj, $username!");
      } else {
        // Scenariusz krytyczny: PostgreSQL odrzucił rejestrację (np. zajęta nazwa użytkownika).
        // Należy wycofać rejestrację z Firebase, aby uniknąć kont osieroconych.
        await user.delete();
        
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _showErrorSnackBar("Błąd serwera: ${errorData['detail']}");
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
    if (e.code == 'weak-password') {
      errorMessage = "Podane hasło jest zbyt słabe.";
    } else if (e.code == 'email-already-in-use') {
      errorMessage = "Konto z podanym adresem email już istnieje.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Zarejestruj się",
                  style: TextStyle(color: _textColor, fontSize: 28, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                _buildLabel("Nazwa użytkownika:"),
                const SizedBox(height: 8),
                _buildTextField(controller: _usernameController, obscureText: false, keyboardType: TextInputType.text),
                const SizedBox(height: 16),

                _buildLabel("Adres email:"),
                const SizedBox(height: 8),
                _buildTextField(controller: _emailController, obscureText: false, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                
                _buildLabel("Hasło:"),
                const SizedBox(height: 8),
                _buildTextField(controller: _passwordController, obscureText: true, keyboardType: TextInputType.text),
                const SizedBox(height: 16),

                _buildLabel("Powtórz hasło:"),
                const SizedBox(height: 8),
                _buildTextField(controller: _confirmPasswordController, obscureText: true, keyboardType: TextInputType.text),
                const SizedBox(height: 48),
                
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _inputColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                        : Text("Utwórz konto", style: TextStyle(color: _textColor, fontFamily: 'monospace', fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: _textColor, fontFamily: 'monospace', fontSize: 14));
  }

  Widget _buildTextField({required TextEditingController controller, required bool obscureText, required TextInputType keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textColor, fontFamily: 'monospace'),
      decoration: InputDecoration(
        filled: true,
        fillColor: _inputColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
      ),
    );
  }
}