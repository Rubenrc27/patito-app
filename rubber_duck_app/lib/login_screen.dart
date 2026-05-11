import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rubber_duck_app/main_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena usuario y contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse(ApiConfig.loginUrl);
    debugPrint('Intentando login en: $url');
    debugPrint('Datos: ${jsonEncode({'username': username, 'password': password})}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        // Guardar el token JWT
        if (data['token'] != null) {
          await prefs.setString('jwt_token', data['token']);
        }
        
        // El backend devuelve 'userId' pero a veces falta en la respuesta de login
        // Usamos 0 o intentamos extraerlo si viene en otro campo
        final userId = data['userId'] ?? 0;
        await prefs.setInt('userId', userId); 
        
        await prefs.setString('username', data['username'] ?? "User"); 
        
        // El rol viene como una cadena compleja "[ROLE_ADMIN_SUPREMO, ...]"
        String role = data['role'] ?? "USER";
        if (role.contains("ADMIN")) {
          role = "ADMIN";
        } else {
          role = "USER";
        }
        await prefs.setString('role', role); 

        await prefs.setString('profile_name', data['fullName'] ?? ""); 
        await prefs.setString('profile_age', data['age'] ?? ""); 
        await prefs.setString('profile_bio', data['bio'] ?? ""); 
        await prefs.setString('profile_avatar', data['avatar'] ?? "🦆");
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${data['username']}!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario o contraseña incorrectos'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión. ¿Está el backend encendido?'),
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBFfzLRai4I0wwtvAUOYiQbyzT14k_Tk_Z74BvmTvZo4hVhvmAZ0LhkE97cZe1etcuwcprUhbXJO6BKircEWYI2LMaTHeZEDWcdTaVxpJC-ZB_tiU6QJD1Hbvs1D3dihP_5ZKlrxuAfS5naJ0pFq8yZ0qp13T9d-wfksuSWTnQkHfofnEnISLLGr24afwR7gvwpoAH4FwDURSkEy27-7WIBtXNW0-UVJwRlOOeKyV9ILqEP37r0nj1V6Js6vHNDxm2WK712HA5d6KgZ',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: primaryDeepNavy,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.white, size: 64),
                      ),
                    ),
                  ),
                  Container(color: primaryDeepNavy.withValues(alpha: 0.85)),
                  Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryYellow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.flutter_dash, color: primaryDeepNavy, size: 32),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'RubberDuckSurveys',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Your voice shapes our culture.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Participate in key organizational decisions with complete confidence. We combine rigorous enterprise security with an accessible experience because we value honest feedback above all.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '© Corporate Intelligence Platform',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isDesktop) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: secondaryYellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.flutter_dash, color: primaryDeepNavy, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'RubberDuckSurveys',
                              style: TextStyle(
                                color: primaryDeepNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 64),
                      ],
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: primaryDeepNavy,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to access your pending surveys.',
                        style: TextStyle(color: neutralGray, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderGray),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: backgroundLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_outlined, color: tertiaryBlue, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '100% Anonymous Responses',
                                    style: TextStyle(
                                      color: primaryDeepNavy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Login verifies employment status only. Your identity is mathematically unlinked.',
                                    style: TextStyle(color: neutralGray, fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Work Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          hintText: 'name@company.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot password?', style: TextStyle(color: tertiaryBlue, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.key_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Sign In'),
                                    SizedBox(width: 8),
                                    Icon(Icons.login, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: neutralGray, fontSize: 14),
                              children: [
                                TextSpan(text: "¿No tienes cuenta? "),
                                TextSpan(
                                  text: "¡Crea una aquí!",
                                  style: TextStyle(color: tertiaryBlue, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: borderGray),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Protected by enterprise-grade security.',
                          style: TextStyle(color: neutralGray.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
