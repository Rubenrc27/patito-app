import 'dart:io'; // Para manejar archivos de la galería
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controladores de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isEditing = false;
  int _completedCount = 0;

  // Esta variable guardará O BIEN un emoji ("🦆") O BIEN una ruta de archivo ("/data/.../image.jpg")
  String _currentAvatar = "🦆"; 

  // Lista de avatares predefinidos (Emojis de animales)
  final List<String> _emojiAvatars = ["🦆", "🦅", "🦉", "🦩", "🐧", "🐤", "🐼", "🦊", "🦁", "🐸", "🐙", "🦄"];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- 1. CARGAR DATOS ---
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? "Usuario Pato";
      _ageController.text = prefs.getString('profile_age') ?? "";
      _bioController.text = prefs.getString('profile_bio') ?? "¡Hola! Me encantan las encuestas.";
      
      // Cargamos el avatar. Si no existe, ponemos el pato por defecto.
      _currentAvatar = prefs.getString('profile_avatar') ?? "🦆";

      List<String> completed = prefs.getStringList('completed_surveys') ?? [];
      _completedCount = completed.length;
    });
  }

  // --- 2. GUARDAR DATOS ---
  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_age', _ageController.text);
    await prefs.setString('profile_bio', _bioController.text);
    
    // Guardamos la cadena actual (sea emoji o ruta de archivo)
    await prefs.setString('profile_avatar', _currentAvatar);

    // =============================================================================
    final int userId = prefs.getInt('userId') ?? 0;
    if (userId != 0) {
      try {
        final url = Uri.parse('http://127.0.0.1:8080/api/auth/profile/$userId');
        await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullName': _nameController.text,
            'age': _ageController.text,
            'bio': _bioController.text,
            'avatar': _currentAvatar,
          }),
        );
      } catch (e) {
        debugPrint("Error de sincronización con servidor: $e");
      }
    }
    // ==============================================================================

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Perfil guardado! 💾"), backgroundColor: Colors.green));
    }
  }

  // --- 3. ELEGIR FOTO DE GALERÍA ---
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _currentAvatar = image.path; // Guardamos la RUTA del archivo
        });
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Cerramos el menú
      }
    } catch (e) {
      debugPrint("Error galería: $e");
    }
  }

  // --- 4. FUNCIÓN INTELIGENTE PARA MOSTRAR EL AVATAR ---
  // Esta función decide si pintar un Texto (Emoji) o una Imagen (Foto)
  Widget _buildAvatarWidget() {
    // Verificamos si _currentAvatar parece una ruta de archivo y si el archivo existe
    bool isFile = _currentAvatar.length > 5 && File(_currentAvatar).existsSync();

    if (isFile) {
      // SI ES FOTO DE GALERÍA:
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: duckYellow, width: 4),
          image: DecorationImage(
            image: FileImage(File(_currentAvatar)),
            fit: BoxFit.cover,
          ),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
        ),
      );
    } else {
      // SI ES UN EMOJI DE ANIMAL:
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: duckYellow.withOpacity(0.3), // ignore: deprecated_member_use
          border: Border.all(color: duckYellow, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
        ),
        child: Center(
          child: Text(
            _currentAvatar, // Pintamos el emoji
            style: const TextStyle(fontSize: 60),
          ),
        ),
      );
    }
  }

  String _getRank() {
    if (_completedCount >= 10) return "Pato Legendario 👑";
    if (_completedCount >= 5) return "Pato Experto 🎓";
    return "Pato Novato 🐣";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, size: 28),
            color: _isEditing ? duckYellow : Colors.white,
            onPressed: () {
              if (_isEditing) _saveProfileData();
              else setState(() => _isEditing = true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- TARJETA DE USUARIO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]), // ignore: deprecated_member_use
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _showAvatarOptions : null, // Solo abre menú si estamos editando
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // AQUÍ LLAMAMOS A LA FUNCIÓN QUE PINTA EL AVATAR
                        _buildAvatarWidget(),
                        
                        // Icono de camarita si estamos editando
                        if (_isEditing)
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: duckDark,
                            child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(_nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: duckDark)),
                  Text(_getRank(), style: TextStyle(fontSize: 14, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildStat("Encuestas", _completedCount.toString()), _buildStat("Puntos", "${_completedCount * 10}"), _buildStat("Edad", _ageController.text.isEmpty ? "-" : _ageController.text)]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // --- FORMULARIO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildTextField("Nombre", _nameController, Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField("Edad", _ageController, Icons.cake, isNumber: true),
                  const SizedBox(height: 15),
                  _buildTextField("Bio", _bioController, Icons.description, maxLines: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) => Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: duckDark)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]);

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller, enabled: _isEditing, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: _isEditing ? Colors.white : Colors.grey.shade100),
    );
  }

  // --- MENÚ DESPLEGABLE INFERIOR ---
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350, // Altura del menú
          child: Column(
            children: [
              const Text("Cambiar Avatar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: duckDark)),
              const SizedBox(height: 20),
              
              // OPCIÓN A: GALERÍA
              ListTile(
                leading: const CircleAvatar(backgroundColor: duckDark, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text("Subir foto de mi galería"),
                subtitle: const Text("Usa una foto real tuya"),
                onTap: _pickImageFromGallery,
              ),
              
              const Divider(height: 30),
              
              const Text("O elige un animal:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // OPCIÓN B: GRID DE EMOJIS
              Expanded(
                child: GridView.builder(
                  itemCount: _emojiAvatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentAvatar = _emojiAvatars[index]); // Seleccionamos emoji
                        Navigator.pop(ctx);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        child: Text(_emojiAvatars[index], style: const TextStyle(fontSize: 30)),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}