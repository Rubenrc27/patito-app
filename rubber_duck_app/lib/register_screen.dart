import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Controladores para capturar lo que escribe el usuario
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isLoading = false;

  // --- FUNCIÓN PARA ENVIAR DATOS A SPRING BOOT ---
  Future<void> _register() async {
    final username = _userController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    // Validación básica: que no haya campos vacíos
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Rellena todos los campos para nacer! 🥚')),
      );
      return;
    }

    setState(() => _isLoading = true); // Activar ruedita de carga

    final url = Uri.parse(ApiConfig.registerUrl);
    debugPrint('Intentando registro en: $url');
    debugPrint('Datos: ${jsonEncode({
      'username': username,
      'email': email,
      'password': password,
    })}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // --- ÉXITO: EL USUARIO SE CREÓ ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ya puedes entrar 🐣'),
            backgroundColor: Colors.green,
          ),
        );
        // Cerramos la pantalla de registro para volver al Login
        Navigator.pop(context); 
        
      } else {
        // --- ERROR: EL USUARIO YA EXISTE O FALLÓ ALGO ---
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Ese usuario ya existe o hubo un fallo 🛑'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // --- ERROR DE CONEXIÓN ---
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión con el servidor 🔌'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores del tema Pato
    const Color duckYellow = Color(0xFFFFD54F);
    const Color duckDark = Color(0xFF3E2723);

    return Scaffold(
      // Barra superior sencilla para volver atrás
      appBar: AppBar(
        backgroundColor: duckYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: duckDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Nuevo Pato", style: TextStyle(color: duckDark, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [duckYellow, duckDark],
            stops: [0.1, 0.9],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Icono decorativo (Un huevo o patito naciendo)
              const Icon(Icons.egg, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Únete al estanque",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              
              // TARJETA BLANCA CON EL FORMULARIO
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    // CAMPO USUARIO
                    TextField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: const Icon(Icons.person, color: duckDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // CAMPO EMAIL (Nuevo)
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email, color: duckDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // CAMPO CONTRASEÑA
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock, color: duckDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // BOTÓN REGISTRARSE
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: duckDark,
                          foregroundColor: Colors.white, // Texto blanco
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('CREAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}