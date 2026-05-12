import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'splash_screen.dart';
import 'main_screen.dart';
import 'sound_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager.init();

  final prefs = await SharedPreferences.getInstance();
  final bool splashSeen = prefs.getBool('splash_seen') ?? false;

  runApp(MyApp(splashSeen: splashSeen));
}

class MyApp extends StatelessWidget {
  final bool splashSeen;

  const MyApp({super.key, required this.splashSeen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubber Duck Surveys',
      debugShowCheckedModeBanner: false,
      color: primaryDeepNavy,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryDeepNavy,
          primary: primaryDeepNavy,
          secondary: secondaryYellow,
          surface: surfaceWhite,
          error: errorRed,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDeepNavy,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryYellow,
            foregroundColor: primaryDeepNavy,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceWhite,
          elevation: 2,
          shadowColor: primaryDeepNavy.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: tertiaryBlue, width: 2),
          ),
          labelStyle: const TextStyle(color: neutralGray),
          prefixIconColor: neutralGray,
        ),
      ),
      builder: (context, child) {
        return Container(
          color: primaryDeepNavy, // Escudo contra el flash blanco inicial
          child: Listener(
            onPointerDown: (_) {
              SoundManager.play();
            },
            child: child!,
          ),
        );
      },
      home: splashSeen ? const MainScreen() : const SplashScreen(),
    );
  }
}