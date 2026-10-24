import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Wrap everything in try-catch to see errors
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('Starting app initialization...');
    
    // Load environment variables
    print('Loading .env file...');
    try {
      await dotenv.load(fileName: ".env");
      print('.env loaded successfully');
    } catch (e) {
      print('⚠️ .env file not found. Ensure .env is copied from .env.example.');
    }
    
    // Check if API key is loaded
    final apiKey = dotenv.env['YOUTUBE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('WARNING: YOUTUBE_API_KEY is not set in .env file');
    } else {
      print('API key loaded: ${apiKey.substring(0, 5)}...');
    }
    
    // Initialize Hive
    print('Initializing Hive...');
    await Hive.initFlutter();
    await Hive.openBox('cache');
    await Hive.openBox('favorites');
    await Hive.openBox('analytics');
    print('Hive initialized successfully');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('ERROR during initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Run app with error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yutanz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFFF0000),
        scaffoldBackgroundColor: const Color(0xFF0F1724),
        cardColor: const Color(0xFF0B1220),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF0000),
          secondary: Color(0xFFFF0000),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1220),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0B1220),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B1220),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF0000)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF0000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}