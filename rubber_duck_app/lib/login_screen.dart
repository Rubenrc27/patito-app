import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'register_screen.dart'; // <--- ASEGÚRATE DE QUE ESTE IMPORT ESTÉ AQUÍ

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena usuario y contraseña 🦆')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Túnel ADB: adb reverse tcp:8080 tcp:8080
    final url = Uri.parse('http://127.0.0.1:8080/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido al estanque, ${data['username']}! 👋'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SurveyListScreen()),
        );
        
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrectos 🛑'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión 🔌. Revisa el túnel ADB.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color duckYellow = Color(0xFFFFD54F);
    const Color duckDark = Color(0xFF3E2723);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [duckYellow, duckDark],
            stops: [0.3, 0.9],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO PRINCIPAL
                SizedBox(
                  height: 250, 
                  child: Image.asset(
                    'assets/duck_icon_login.png', 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('🦆', style: TextStyle(fontSize: 150));
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  'Rubber Duck Surveys',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 10.0, color: Colors.black45, offset: Offset(2.0, 2.0)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Identifícate para entrar al estanque',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 50),

                // 2. TARJETA FORMULARIO (Caja Blanca)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userController,
                        decoration: InputDecoration(
                          labelText: 'Usuario',
                          labelStyle: TextStyle(color: duckDark),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset(
                              'assets/icono_pato.png', 
                              width: 40, height: 40,
                              errorBuilder: (context, error, stackTrace) => 
                                const Text('👤', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: duckYellow, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: duckDark),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: const Text('🔒', style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: duckYellow, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: duckYellow,
                            foregroundColor: duckDark,
                            elevation: 5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 24, width: 24,
                                  child: CircularProgressIndicator(color: duckDark, strokeWidth: 3))
                              : const Text(
                                  'ZAMBULLIRSE',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                        ),
                      ),
                    ],
                  ),
                ), // <--- AQUÍ TERMINA LA CAJA BLANCA

                // 👇👇 AQUÍ ESTÁ EL BOTÓN DE REGISTRO NUEVO 👇👇
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? ¡Crea una aquí!',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Un poco de espacio extra al final
                // 👆👆 FIN DEL BOTÓN DE REGISTRO 👆👆

              ], // Fin de la Column
            ),
          ),
        ),
      ),
    );
  }
}