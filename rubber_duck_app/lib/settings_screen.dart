import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'splash_screen.dart';
import 'sound_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _duckSounds = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _duckSounds = SoundManager.isEnabled;
    });
  }

  Future<void> _factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    await SoundManager.setSound(false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (route) => false
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("Ajustes del Sistema"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _SectionHeader(title: "Preferencias de la Aplicación"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: tertiaryBlue,
                  title: const Text("Notificaciones Push"),
                  subtitle: const Text("Recibe alertas sobre nuevas encuestas y reportes."),
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                  secondary: const Icon(Icons.notifications_active_outlined, color: primaryDeepNavy),
                ),
                const Divider(height: 1, indent: 70, color: borderGray),
                SwitchListTile(
                  activeThumbColor: tertiaryBlue,
                  title: const Text("Feedback de Audio"),
                  subtitle: const Text("Activa efectos de sonido suaves al interactuar."),
                  value: _duckSounds,
                  onChanged: (val) {
                    setState(() => _duckSounds = val);
                    SoundManager.setSound(val);
                    if (val) SoundManager.play();
                  },
                  secondary: const Icon(Icons.volume_up_outlined, color: primaryDeepNavy),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const _SectionHeader(title: "Seguridad y Datos"),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: errorRed),
              title: const Text("Restablecer de Fábrica"),
              subtitle: const Text("Borra todos los datos locales y del perfil."),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Confirmar Borrado de Datos"),
                    content: const Text("Esta acción eliminará permanentemente toda la información del perfil y los datos guardados. No se puede deshacer."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _factoryReset();
                        }, 
                        child: const Text("BORRAR TODO", style: TextStyle(color: errorRed, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const _SectionHeader(title: "Información de la Plataforma"),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: neutralGray),
                  title: Text("Versión"),
                  trailing: Text("1.2.0-PRO", style: TextStyle(color: neutralGray, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, indent: 70, color: borderGray),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: neutralGray),
                  title: const Text("Acuerdo de Servicio"),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "RubberDuckSurveys",
                      applicationVersion: "1.2.0-PRO",
                      applicationIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: secondaryYellow, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.flutter_dash, color: primaryDeepNavy),
                      ),
                      children: [
                        const Text("Plataforma de Inteligencia de Feedback para empresas."),
                        const Text("Diseñada para entornos corporativos de alto rendimiento."),
                      ]
                    );
                  },
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: neutralGray, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}
