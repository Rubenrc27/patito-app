import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _splashData = [
    {
      "title": "¡Bienvenido a Rubber Duck!",
      "description": "Tu voz es fundamental para nuestra cultura organizacional. Participa y ayúdanos a mejorar.",
      "image": "🦆",
    },
    {
      "title": "¿De qué trata la App?",
      "description": "Recopilamos feedback anónimo para tomar mejores decisiones. Tu identidad está protegida matemáticamente.",
      "image": "📊",
    },
    {
      "title": "Términos de Uso",
      "description": "Al continuar, aceptas que tus respuestas sean procesadas de forma anónima para fines de mejora continua.",
      "image": "📜",
    },
  ];

  Future<void> _completeSplash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('splash_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDeepNavy,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _splashData.length,
            itemBuilder: (context, index) => _buildPage(index),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _splashData.length,
                    (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _splashData.length - 1) {
                          _completeSplash();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryYellow,
                        foregroundColor: primaryDeepNavy,
                      ),
                      child: Text(
                        _currentPage == _splashData.length - 1 ? "ACEPTAR Y EMPEZAR" : "SIGUIENTE",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _splashData[index]["image"]!,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              _splashData[index]["title"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryDeepNavy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _splashData[index]["description"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: neutralGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _currentPage == index ? secondaryYellow : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
