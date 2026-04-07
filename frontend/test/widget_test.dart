import 'package:flutter_test/flutter_test.dart';

// Import głównego pliku aplikacji. 
// Zmień 'frontend' na dokładną nazwę Twojego projektu z pliku pubspec.yaml (pole name:).
import 'package:frontend/main.dart'; 

void main() {
  testWidgets('Weryfikacja renderowania ekranu logowania', (WidgetTester tester) async {
    // Zbudowanie aplikacji i wyzwolenie renderowania pierwszej klatki
    await tester.pumpWidget(const GymApp());

    // Weryfikacja, czy na ekranie pojawia się tekst z przycisku logowania oraz etykiety
    expect(find.text('Zaloguj się'), findsWidgets);
    expect(find.text('Adres email:'), findsOneWidget);
    
    // Weryfikacja, czy standardowy licznik z domyślnej aplikacji Fluttera nie istnieje
    expect(find.text('0'), findsNothing);
  });
}