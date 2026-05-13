import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'shared_widgets.dart';
import 'api_config.dart';
import 'models.dart';

class CreateSurveyScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback onGoToProfile;
  final Survey? surveyToEdit; 
  const CreateSurveyScreen({super.key, required this.isLoggedIn, required this.onGoToProfile, this.surveyToEdit});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedAvatar = 'CLASSIC';
  final List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _isChecking = true;

  final List<String> _avatars = ['CLASSIC', 'GRADUATE', 'INVESTIGATOR', 'DEV', 'OFFICE'];

  @override
  void initState() {
    super.initState();
    _checkRole();
    if (widget.surveyToEdit != null) {
      _loadSurveyData(widget.surveyToEdit!);
    } else {
      _addQuestion();
    }
  }

  void _loadSurveyData(Survey survey) {
    _titleController.text = survey.title;
    _descController.text = survey.description;
    _selectedAvatar = survey.duckAvatar;
    
    for (var q in survey.questions) {
      _questions.add({
        'id': q.id,
        'controller': TextEditingController(text: q.text),
        'type': q.type,
        'options': q.options.map((o) => TextEditingController(text: o.text)).toList(),
      });
    }
  }

  @override
  void didUpdateWidget(CreateSurveyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != oldWidget.isLoggedIn) {
      _checkRole();
    }
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isAdmin = prefs.getString('role') == 'ADMIN';
        _isChecking = false;
      });
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'controller': TextEditingController(),
        'type': 'SINGLE',
        'options': [TextEditingController(text: 'Opción 1'), TextEditingController(text: 'Opción 2')],
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addOption(int qIndex) {
    setState(() {
      _questions[qIndex]['options'].add(TextEditingController(text: 'Nueva Opción'));
    });
  }

  void _removeOption(int qIndex, int oIndex) {
    setState(() {
      _questions[qIndex]['options'].removeAt(oIndex);
    });
  }

  Future<void> _publishSurvey() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El título es obligatorio")));
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final bool isEditing = widget.surveyToEdit != null;

    final payload = {
      if (isEditing) 'id': widget.surveyToEdit!.id,
      'title': _titleController.text,
      'description': _descController.text,
      'duckAvatar': _selectedAvatar,
      'isActive': true,
      'questions': _questions.map((q) {
        return {
          if (isEditing && q['id'] != null) 'id': q['id'],
          'questionText': (q['controller'] as TextEditingController).text,
          'questionType': q['type'],
          'options': (q['type'] == 'OPEN') 
            ? [] 
            : (q['options'] as List<TextEditingController>).map((o) => {'optionText': o.text}).toList(),
        };
      }).toList(),
    };

    try {
      final url = isEditing 
          ? Uri.parse('${ApiConfig.surveysUrl}/${widget.surveyToEdit!.id}')
          : Uri.parse('${ApiConfig.surveysUrl}/create');

      final response = isEditing
          ? await http.put(
              url,
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditing ? "¡Encuesta actualizada!" : "¡Encuesta publicada con éxito!"), 
          backgroundColor: Colors.green
        ));
        
        if (isEditing) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _titleController.clear();
            _descController.clear();
            _selectedAvatar = 'CLASSIC';
            _questions.clear();
            _addQuestion();
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) return buildPlaceholder(context, "Crear Nueva Encuesta", widget.onGoToProfile);
    if (_isChecking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_isAdmin) return _buildNoAdminAccess();

    final bool isEditing = widget.surveyToEdit != null;

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? "Editar Encuesta" : "Diseñador de Encuestas"),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
          else
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.rocket_launch, color: secondaryYellow),
              onPressed: _publishSurvey,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? "Editando Encuesta" : "Nueva Encuesta",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryDeepNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              "Configura los detalles generales y añade tus preguntas.",
              style: TextStyle(fontSize: 16, color: neutralGray),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Detalles Generales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
                    const SizedBox(height: 24),
                    _buildLabel("Título"),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: "ej., Satisfacción del Cliente"),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Descripción"),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: "Explica el propósito de esta encuesta..."),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Avatar del Pato"),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAvatar,
                      items: _avatars.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _selectedAvatar = v!),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text("Preguntas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
            const SizedBox(height: 16),
            ..._questions.asMap().entries.map((entry) => _buildQuestionCard(entry.key, entry.value)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text("Añadir Pregunta"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: tertiaryBlue),
                foregroundColor: tertiaryBlue,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _publishSurvey,
        backgroundColor: primaryDeepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.publish),
        label: const Text("Publicar"),
      ),
    );
  }

  Widget _buildNoAdminAccess() {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 80, color: borderGray),
              const SizedBox(height: 24),
              const Text("Acceso Restringido", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
              const SizedBox(height: 16),
              const Text(
                "Solo los administradores pueden crear nuevas encuestas. Si crees que deberías tener acceso, contacta con soporte.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: neutralGray),
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: widget.onGoToProfile, child: const Text("VOLVER AL PERFIL")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryDeepNavy)),
    );
  }

  Widget _buildQuestionCard(int idx, Map<String, dynamic> q) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pregunta #${idx + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: tertiaryBlue)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: errorRed),
                  onPressed: () => _removeQuestion(idx),
                )
              ],
            ),
            const SizedBox(height: 8),
            _buildLabel("Texto de la Pregunta"),
            TextField(
              controller: q['controller'] as TextEditingController,
              decoration: const InputDecoration(hintText: "¿Qué opinas sobre...?"),
            ),
            const SizedBox(height: 16),
            _buildLabel("Tipo de Respuesta"),
            DropdownButtonFormField<String>(
              initialValue: q['type'],
              items: const [
                DropdownMenuItem(value: 'SINGLE', child: Text("Opción Única")),
                DropdownMenuItem(value: 'MULTIPLE', child: Text("Opción Múltiple")),
                DropdownMenuItem(value: 'OPEN', child: Text("Texto Libre")),
              ],
              onChanged: (val) {
                setState(() => q['type'] = val);
              },
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
            if (q['type'] != 'OPEN') ...[
              const SizedBox(height: 24),
              _buildLabel("Opciones"),
              ...(q['options'] as List<TextEditingController>).asMap().entries.map((optEntry) {
                int oIdx = optEntry.key;
                var oCtrl = optEntry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: oCtrl,
                          decoration: InputDecoration(
                            hintText: "Opción ${oIdx + 1}",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20, color: neutralGray),
                        onPressed: () => _removeOption(idx, oIdx),
                      )
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addOption(idx),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Añadir Opción"),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onGoToProfile;
  const AnalyticsScreen({super.key, required this.isLoggedIn, required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return buildPlaceholder(context, "Análisis de Datos", onGoToProfile);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(title: const Text("Análisis de Encuestas")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Análisis de Encuestas",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryDeepNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sigue el compromiso y visualiza el feedback del equipo en tiempo real.",
              style: TextStyle(fontSize: 16, color: neutralGray),
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard("Total Respuestas", "1,284", Icons.people_outline, tertiaryBlue),
                _buildStatCard("Tasa de Finalización", "84%", Icons.donut_large, Colors.green),
                _buildStatCard("Tiempo Medio", "12m", Icons.timer_outlined, Colors.orange),
                _buildStatCard("Puntuación NPS", "72", Icons.trending_up, secondaryYellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: neutralGray, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
          ],
        ),
      ),
    );
  }
}
