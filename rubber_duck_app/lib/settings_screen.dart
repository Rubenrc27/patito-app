import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'login_screen.dart';
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
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("System Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _SectionHeader(title: "Application Preferences"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: tertiaryBlue,
                  title: const Text("Push Notifications"),
                  subtitle: const Text("Receive alerts for new surveys and reports."),
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                  secondary: const Icon(Icons.notifications_active_outlined, color: primaryDeepNavy),
                ),
                const Divider(height: 1, indent: 70, color: borderGray),
                SwitchListTile(
                  activeThumbColor: tertiaryBlue,
                  title: const Text("Audio Feedback"),
                  subtitle: const Text("Enable subtle audio cues for interactions."),
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
          const _SectionHeader(title: "Security & Data"),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: errorRed),
              title: const Text("Factory Reset"),
              subtitle: const Text("Delete all local data and profile settings."),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Confirm Data Erasure"),
                    content: const Text("This action will permanently remove all profile information and local cached data. This cannot be undone."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _factoryReset();
                        }, 
                        child: const Text("ERASE ALL", style: TextStyle(color: errorRed, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const _SectionHeader(title: "Platform Information"),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: neutralGray),
                  title: Text("Version"),
                  trailing: Text("1.2.0-PRO", style: TextStyle(color: neutralGray, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, indent: 70, color: borderGray),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: neutralGray),
                  title: const Text("Service Agreement"),
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
                        const Text("Enterprise-grade Feedback Intelligence Platform."),
                        const Text("Designed for high-performance corporate environments."),
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
