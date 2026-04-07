import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Definicja kolorystyki spójnej z resztą aplikacji
  final Color _backgroundColor = const Color(0xFF161521);
  final Color _accentColor = const Color(0xFFD9D9D9);
  final Color _unselectedColor = const Color(0xFF4A464B);

  // Lista ekranów (modułów), między którymi użytkownik będzie się przełączał.
  // Na tym etapie są to widoki zastępcze (Placeholders).
  final List<Widget> _screens = [
    const Center(child: Text('Pulpit', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 24))),
    const Center(child: Text('Plany Treningowe', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 24))),
    const Center(child: Text('Historia', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 24))),
    const ProfilePlaceholderScreen(), // Ekran profilu z logiką wylogowania
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      // Wykorzystanie IndexedStack zapobiega przeładowywaniu ekranów i utracie ich stanu (np. pozycji przewijania)
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _backgroundColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _accentColor,
        unselectedItemColor: _unselectedColor,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Pulpit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Trening',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// Tymczasowy ekran profilu z zaimplementowaną logiką wylogowania
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Zabezpieczenie przed użyciem context po Async Gap
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd podczas wylogowywania: $e", style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profil użytkownika', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 24)),
          const SizedBox(height: 16),
          Text(user?.email ?? 'Brak e-maila', style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 16)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => _handleLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Wyloguj się', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
          )
        ],
      ),
    );
  }
}