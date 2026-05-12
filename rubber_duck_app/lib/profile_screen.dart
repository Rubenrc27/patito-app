import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'colors.dart';
import 'api_config.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const ProfileScreen({super.key, required this.onLoginSuccess});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Login controllers
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _obscurePassword = true;
  int _completedCount = 0;
  String _currentAvatar = "🦆"; 

  final List<String> _emojiAvatars = ["🦆", "🦅", "🦉", "🦩", "🐧", "🐤", "🐼", "🦊", "🦁", "🐸", "🐙", "🦄"];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;
    if (userId != 0) {
      setState(() => _isLoggedIn = true);
      _loadProfileData();
    } else {
      setState(() => _isLoggedIn = false);
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? "Consultant Name";
      _ageController.text = prefs.getString('profile_age') ?? "";
      _bioController.text = prefs.getString('profile_bio') ?? "Professional Consultant specializing in data-driven insights.";
      _currentAvatar = prefs.getString('profile_avatar') ?? "🦆";
      List<String> completed = prefs.getStringList('completed_surveys') ?? [];
      _completedCount = completed.length;
    });
  }

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, rellena usuario y contraseña')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        if (data['token'] != null) await prefs.setString('jwt_token', data['token']);
        
        final userId = data['userId'] ?? data['id'] ?? 0;
        await prefs.setInt('userId', userId); 
        await prefs.setString('username', data['username'] ?? "User"); 
        
        String role = data['role'] ?? "USER";
        await prefs.setString('role', role.contains("ADMIN") ? "ADMIN" : "USER"); 

        await prefs.setString('profile_name', data['fullName'] ?? ""); 
        await prefs.setString('profile_age', data['age']?.toString() ?? ""); 
        await prefs.setString('profile_bio', data['bio'] ?? ""); 
        await prefs.setString('profile_avatar', data['avatar'] ?? "🦆");
        
        if (!mounted) return;
        
        widget.onLoginSuccess();
        _checkLoginStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Bienvenido, ${data['username']}!'), backgroundColor: Colors.green));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña incorrectos'), backgroundColor: errorRed));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.orangeAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    widget.onLoginSuccess(); // Notify main screen
    _checkLoginStatus();
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_age', _ageController.text);
    await prefs.setString('profile_bio', _bioController.text);
    await prefs.setString('profile_avatar', _currentAvatar);

    final int userId = prefs.getInt('userId') ?? 0;
    final String? token = prefs.getString('jwt_token');

    if (userId != 0) {
      try {
        final url = Uri.parse(ApiConfig.profileUrl(userId));
        await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fullName': _nameController.text,
            'age': _ageController.text,
            'bio': _bioController.text,
            'avatar': _currentAvatar,
          }),
        );
      } catch (e) {
        debugPrint("Error syncing profile: $e");
      }
    }

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully."), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return _buildLoginView();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("User Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfileData();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: errorRed),
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _showAvatarOptions : null,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _buildAvatarWidget(),
                          if (_isEditing)
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryDeepNavy,
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _nameController.text,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryDeepNavy),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: tertiaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRank(),
                        style: const TextStyle(fontSize: 12, color: tertiaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat("Surveys", _completedCount.toString()),
                        _buildStat("Points", "${_completedCount * 10}"),
                        _buildStat("Age", _ageController.text.isEmpty ? "-" : _ageController.text),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
                    const SizedBox(height: 24),
                    _buildTextField("Full Name", _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField("Age", _ageController, Icons.cake_outlined, isNumber: true),
                    const SizedBox(height: 16),
                    _buildTextField("Biography", _bioController, Icons.description_outlined, maxLines: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Identificación', style: TextStyle(color: primaryDeepNavy, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Inicia sesión para acceder a todas las funciones.', style: TextStyle(color: neutralGray, fontSize: 16)),
                const SizedBox(height: 32),
                const Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(hintText: 'Tu usuario', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 24),
                const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text("¿No tienes cuenta? ¡Crea una aquí!", style: TextStyle(color: tertiaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    bool isFile = _currentAvatar.length > 5 && File(_currentAvatar).existsSync();
    if (isFile) {
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderGray, width: 4),
          image: DecorationImage(image: FileImage(File(_currentAvatar)), fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: secondaryYellow.withValues(alpha: 0.2),
          border: Border.all(color: secondaryYellow, width: 4),
        ),
        child: Center(child: Text(_currentAvatar, style: const TextStyle(fontSize: 60))),
      );
    }
  }

  String _getRank() {
    if (_completedCount >= 10) return "Expert Advisor";
    if (_completedCount >= 5) return "Senior Consultant";
    return "Associate Consultant";
  }

  Widget _buildStat(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
      Text(label, style: const TextStyle(fontSize: 12, color: neutralGray)),
    ],
  );

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryDeepNavy)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: _isEditing ? surfaceWhite : backgroundLight,
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(32),
          height: 400,
          child: Column(
            children: [
              const Text("Cambiar Avatar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _emojiAvatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentAvatar = _emojiAvatars[index]);
                        Navigator.pop(ctx);
                      },
                      child: CircleAvatar(backgroundColor: backgroundLight, child: Text(_emojiAvatars[index], style: const TextStyle(fontSize: 24))),
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
