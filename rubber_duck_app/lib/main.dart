import 'package:flutter/material.dart';
import 'colors.dart';
import 'login_screen.dart';
import 'sound_manager.dart'; // <--- Importante

void main() async {
  // Aseguramos que los plugins (Audio, Prefs) estén listos antes de arrancar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargamos la configuración del sonido (si estaba activado o no)
  await SoundManager.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubber Duck Surveys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: duckYellow),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white, 
            fontSize: 22, 
            fontWeight: FontWeight.bold, 
            shadows: [Shadow(color: Colors.black45, blurRadius: 5)]
          ),
        ),
      ),
      // --- DETECTOR GLOBAL DE TOQUES ---
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) {
            // Cada vez que el dedo toca la pantalla -> Cuack!
            SoundManager.play();
          },
          child: child,
        );
      },
      // ---------------------------------
      home: const LoginScreen(),
    );
  }
}