import 'package:flutter/material.dart';
import 'colors.dart';
import 'surveys_screens.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Definimos las pantallas aquí.
  // Al no usar PageView, cada vez que cambiemos de índice, se reconstruirá la pantalla elegida.
  final List<Widget> _pages = [
    const EstanqueScreen(),      // Pantalla 0
    const MisEncuestasScreen(),  // Pantalla 1
    const ProfileScreen(),       // Pantalla 2
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight, 
            colors: [duckYellow, duckDark], 
            stops: [0.3, 0.9]
          ),
        ),
        // 🦆 AQUÍ ESTÁ EL CAMBIO: Cargamos directamente la página (sin PageView)
        // Esto fuerza a que se recargue ("init") cada vez que cambias de pestaña.
        child: IndexedStack( // Usamos IndexedStack o directamente _pages[_selectedIndex]
          index: _selectedIndex,
          // NOTA: Si quieres que se recargue 100% EXTREMO usa: _pages[_selectedIndex]
          // Si usas IndexedStack guarda estado. 
          // Como tú quieres REFRESCAR, usaremos la opción directa:
          children: _pages, 
        ).children[_selectedIndex], // <--- TRUCO: Accedemos directamente para forzar rebuild
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () { 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Próximamente: Crear nueva encuesta 🦆"))
          ); 
        },
        backgroundColor: duckYellow, 
        elevation: 5, 
        shape: const CircleBorder(), 
        child: const Icon(Icons.add, size: 35, color: duckDark),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), 
        notchMargin: 8.0, 
        color: Colors.white, 
        elevation: 10,
        child: SizedBox(
          height: 60, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: [
              _buildBarItem(icon: Icons.home_rounded, label: "Inicio", index: 0),
              _buildBarItem(icon: Icons.check_circle_rounded, label: "Mis Encuestas", index: 1),
              const SizedBox(width: 40),
              _buildBarItem(icon: Icons.person_rounded, label: "Perfil", index: 2),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey), 
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
            ]
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? duckDark : Colors.grey.shade400, size: isSelected ? 30 : 26), 
      onPressed: () => _onItemTapped(index), 
      tooltip: label
    );
  }
}

// Extensión pequeña para acceder al children del IndexedStack de forma segura si usas el truco de arriba
extension on IndexedStack {
  // Simplemente para que compile el truco de arriba, aunque _pages[_selectedIndex] directo en el body es más limpio.
  // Pero para tu caso, pon en el body simplemente: _pages[_selectedIndex]
}