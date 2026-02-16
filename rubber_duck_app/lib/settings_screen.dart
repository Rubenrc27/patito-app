import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'login_screen.dart';
import 'sound_manager.dart'; // <--- Importamos el gestor de sonido

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estado de los interruptores
  bool _notificationsEnabled = true;
  bool _duckSounds = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Cargar estado real del sonido desde el Manager
  void _loadSettings() {
    setState(() {
      _duckSounds = SoundManager.isEnabled;
    });
  }

  // --- FUNCIÓN: BORRAR HISTORIAL DE ENCUESTAS ---
  Future<void> _resetSurveyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('completed_surveys');
    // Borramos también respuestas guardadas (limpieza genérica de claves que empiecen por survey_)
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('survey_answers_')) {
        await prefs.remove(key);
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Historial borrado! Las encuestas volverán a aparecer."), backgroundColor: Colors.orange),
      );
    }
  }

  // --- FUNCIÓN: BORRAR TODO (REINICIO DE FÁBRICA) ---
  Future<void> _factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ¡BORRA TODO!
    
    // Restablecemos el sonido a apagado en memoria local también
    await SoundManager.setSound(false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ajustes"),
        backgroundColor: duckYellow,
        foregroundColor: duckDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECCIÓN 1: GENERAL
          const _SectionHeader(title: "General"),
          SwitchListTile(
            activeColor: duckYellow,
            title: const Text("Notificaciones Push"),
            subtitle: const Text("Avísame cuando haya nuevas encuestas"),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            secondary: const Icon(Icons.notifications_active, color: duckDark),
          ),
          
          // --- INTERRUPTOR DE SONIDO ---
          SwitchListTile(
            activeColor: duckYellow,
            title: const Text("Sonidos de Pato 🦆"),
            subtitle: const Text("Hacer 'Cuack' al pulsar botones"),
            value: _duckSounds,
            onChanged: (val) {
              setState(() => _duckSounds = val);
              SoundManager.setSound(val); // Guardamos la preferencia
              if (val) SoundManager.play(); // Cuack de confirmación
            },
            secondary: const Icon(Icons.music_note, color: duckDark),
          ),
          // -----------------------------

          const Divider(),

          // SECCIÓN 2: DATOS Y ALMACENAMIENTO
          const _SectionHeader(title: "Zona de Peligro"),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text("Reiniciar Encuestas"),
            subtitle: const Text("Vuelve a hacer todas las encuestas"),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("¿Reiniciar historial?"),
                  content: const Text("Las encuestas completadas volverán a aparecer en Inicio."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetSurveyHistory();
                      }, 
                      child: const Text("Reiniciar", style: TextStyle(color: Colors.orange))
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Borrar cuenta y datos"),
            subtitle: const Text("Eliminar perfil y reiniciar app"),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("¿Estás seguro?"),
                  content: const Text("Se borrará tu nombre, foto y todo el progreso. Es irreversible."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _factoryReset();
                      }, 
                      child: const Text("BORRAR TODO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),

          // SECCIÓN 3: INFO
          const _SectionHeader(title: "Información"),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text("Versión de la App"),
            trailing: const Text("1.0.0 (Beta)", style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.grey),
            title: const Text("Términos y Condiciones"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Rubber Duck Surveys",
                applicationVersion: "1.0.0",
                applicationIcon: const Text("🦆", style: TextStyle(fontSize: 40)),
                children: [
                  const Text("Esta aplicación es un proyecto de aprendizaje."),
                  const Text("Desarrollada con Flutter y mucho café."),
                ]
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}