import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'screens/home_screen.dart';
import 'screens/trip_builder_screen.dart';
import 'screens/booking_screen.dart';

// existing screens
import 'screens/memories_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/login_screen.dart';

// new screens
import 'screens/expense_tracker.dart';
import 'screens/ai_assistant.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
 
  runApp(const TripPlannerApp());
}

class TripPlannerApp extends StatelessWidget {
  const TripPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {

          case '/':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );

          case '/builder':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final destination = args['destination'] as String? ?? '';
            final selectedPlaces =
                args['selectedPlaces'] as List<Map<String, String>>? ?? [];

            return MaterialPageRoute(
              builder: (_) => TripBuilderScreen(
                destination: destination,
                suggestedPlaces: selectedPlaces,
              ),
            );

          case '/bookings':
            return MaterialPageRoute(
              builder: (_) => const BookingScreen(),
            );

          case '/memories':
            return MaterialPageRoute(
              builder: (_) => const MemoriesScreen(),
            );

          case '/favorites':
            return MaterialPageRoute(
              builder: (_) => const FavoritesScreen(),
            );

          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );

          // ✅ NEW ROUTE - Expense Tracker
          case '/expense':
            return MaterialPageRoute(
              builder: (_) => const ExpenseScreen(),
            );

          // 🤖 NEW ROUTE - AI Assistant
          case '/ai':
            return MaterialPageRoute(
              builder: (_) => const AIAssistant(),
            );

          // ⚙️ NEW ROUTE - Settings Screen
          case '/settings':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final email = args['email'] as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => SettingsScreen(email: email),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}