import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool isEnabled = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled = prefs.getBool('duck_sounds') ?? false;
    
    // Configuración para mejor respuesta en Android
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  static Future<void> setSound(bool value) async {
    isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('duck_sounds', value);
  }

  static void play() async {
    if (isEnabled) {
      try {
        if (_player.state == PlayerState.playing) {
          await _player.stop();
        }
        
        // OJO AQUÍ: 'AssetSource' ya sabe que tiene que buscar en la carpeta 'assets'.
        // Solo ponemos la subcarpeta y el archivo.
        await _player.play(AssetSource('quack.mp3'));
        
        print("🔊 Reproduciendo sonido... ");
      } catch (e) {
        print("❌ Error de sonido: $e");
      }
    }
  }
}