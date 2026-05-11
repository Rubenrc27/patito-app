import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'colors.dart';
import 'login_screen.dart';
import 'api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isEditing = false;
  int _completedCount = 0;
  String _currentAvatar = "🦆"; 

  final List<String> _emojiAvatars = ["🦆", "🦅", "🦉", "🦩", "🐧", "🐤", "🐼", "🦊", "🦁", "🐸", "🐙", "🦄"];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (!mounted) return;
        setState(() {
          _currentAvatar = image.path;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Gallery error: $e");
    }
  }

  Widget _buildAvatarWidget() {
    bool isFile = _currentAvatar.length > 5 && File(_currentAvatar).existsSync();

    if (isFile) {
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderGray, width: 4),
          image: DecorationImage(
            image: FileImage(File(_currentAvatar)),
            fit: BoxFit.cover,
          ),
          boxShadow: [BoxShadow(color: primaryDeepNavy.withValues(alpha: 0.1), blurRadius: 20)]
        ),
      );
    } else {
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: secondaryYellow.withValues(alpha: 0.2),
          border: Border.all(color: secondaryYellow, width: 4),
          boxShadow: [BoxShadow(color: primaryDeepNavy.withValues(alpha: 0.1), blurRadius: 20)]
        ),
        child: Center(
          child: Text(
            _currentAvatar,
            style: const TextStyle(fontSize: 60),
          ),
        ),
      );
    }
  }

  String _getRank() {
    if (_completedCount >= 10) return "Expert Advisor";
    if (_completedCount >= 5) return "Senior Consultant";
    return "Associate Consultant";
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
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
              const Text("Change Profile Identity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(backgroundColor: primaryDeepNavy, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text("Upload professional photo"),
                subtitle: const Text("Select from your device gallery"),
                onTap: _pickImageFromGallery,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: borderGray),
              ),
              const Text("Select representative icon:", style: TextStyle(color: neutralGray, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 16),
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
                      child: CircleAvatar(
                        backgroundColor: backgroundLight,
                        child: Text(_emojiAvatars[index], style: const TextStyle(fontSize: 24)),
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
