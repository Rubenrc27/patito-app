import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'models.dart';

// 🦆 URL CENTRALIZADA
const String baseUrl = 'https://careful-noninvidiously-nettie.ngrok-free.dev';

// =============================================================================
// 🌊 PANTALLA 1: ESTANQUE
// =============================================================================
class EstanqueScreen extends StatefulWidget {
  const EstanqueScreen({super.key});

  @override
  State<EstanqueScreen> createState() => _EstanqueScreenState();
}

class _EstanqueScreenState extends State<EstanqueScreen> {
  List<Survey> surveys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    try {
      final urlAll = Uri.parse('$baseUrl/api/surveys');
      final urlMine = Uri.parse('$baseUrl/api/surveys/mis-encuestas?userId=$userId');

      final responses = await Future.wait([http.get(urlAll), http.get(urlMine)]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final List<dynamic> allJson = json.decode(utf8.decode(responses[0].bodyBytes));
        final List<dynamic> mineJson = json.decode(utf8.decode(responses[1].bodyBytes));
        final Set<int> myCompletedIds = mineJson.map((e) => e['id'] as int).toSet();

        if (mounted) {
          setState(() {
            surveys = allJson
                .map((e) => Survey.fromJson(e))
                .where((s) => !myCompletedIds.contains(s.id))
                .toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Estanque de Encuestas"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => isLoading = true); _loadData(); })
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : surveys.isEmpty
              ? _buildEmptyState("¡Estanque limpio!", Icons.done_all)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: surveys.length,
                  itemBuilder: (context, index) => _buildSurveyCard(context, surveys[index], isCompleted: false),
                ),
    );
  }
}

// =============================================================================
// ✅ PANTALLA 2: MIS ENCUESTAS
// =============================================================================
class MisEncuestasScreen extends StatefulWidget {
  const MisEncuestasScreen({super.key});

  @override
  State<MisEncuestasScreen> createState() => _MisEncuestasScreenState();
}

class _MisEncuestasScreenState extends State<MisEncuestasScreen> {
  List<Survey> surveys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;
    
    final url = Uri.parse('$baseUrl/api/surveys/mis-encuestas?userId=$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            surveys = data.map((e) => Survey.fromJson(e)).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Mis Encuestas"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : surveys.isEmpty
              ? _buildEmptyState("Sin encuestas completadas.", Icons.assignment_late)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: surveys.length,
                  itemBuilder: (context, index) => _buildSurveyCard(context, surveys[index], isCompleted: true),
                ),
    );
  }
}

// =============================================================================
// 📝 PANTALLA 3: DETALLE DE ENCUESTA (Para Responder)
// =============================================================================
class SurveyDetailScreen extends StatefulWidget {
  final Survey survey;
  const SurveyDetailScreen({super.key, required this.survey});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  final Map<int, dynamic> _answers = {}; 
  bool isSubmitting = false;

  Future<void> submitAnswers() async {
    setState(() => isSubmitting = true);
    
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    // 🦆 CONSTRUCCIÓN DEL PAYLOAD PARA SPRING BOOT
    List<Map<String, dynamic>> payload = [];
    
    _answers.forEach((questionId, value) {
      if (value is List) {
        // SELECCIÓN MÚLTIPLE: Enviamos un objeto independiente por cada opción
        for (var optionId in value) {
          payload.add({
            "questionId": questionId, 
            "optionId": optionId,
            "surveyId": widget.survey.id
          });
        }
      } else if (value is int) {
        // SELECCIÓN ÚNICA
        payload.add({
          "questionId": questionId, 
          "optionId": value,
          "surveyId": widget.survey.id
        });
      } else if (value is String && value.trim().isNotEmpty) {
        // TEXTO LIBRE
        payload.add({
          "questionId": questionId, 
          "text": value,
          "surveyId": widget.survey.id
        });
      }
    });

    final url = Uri.parse('$baseUrl/api/surveys/submit?userId=$userId');

    try {
      final response = await http.post(
        url, 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(payload)
      );

      // Verificamos éxito (200 o 201)
      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        Map<String, dynamic> answersToSave = _answers.map((k, v) => MapEntry(k.toString(), v));
        await prefs.setString('survey_answers_${widget.survey.id}', jsonEncode(answersToSave));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Enviado con éxito! 🦆'), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true); 
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}'))
        );
      }
    } catch (e) { 
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión 🔌'))
      ); 
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.survey.title), 
        backgroundColor: duckYellow, 
        foregroundColor: duckDark, 
        elevation: 0
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.survey.questions.length + 1,
        itemBuilder: (context, index) {
          
          if (index == widget.survey.questions.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 40), 
              child: SizedBox(
                height: 50, 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: duckDark, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  onPressed: (isSubmitting || _answers.isEmpty) ? null : submitAnswers, 
                  child: isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ENVIAR RESPUESTAS", style: TextStyle(fontWeight: FontWeight.bold))
                )
              )
            );
          }

          final question = widget.survey.questions[index];
          return Card(
            color: Colors.white, 
            elevation: 3, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text("${index + 1}. ${question.text}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: duckDark)),
                  const SizedBox(height: 10),
                  
                  if (question.type == 'SINGLE') 
                    ...question.options.map((opt) => RadioListTile<int>(
                      title: Text(opt.text), 
                      value: opt.id, 
                      groupValue: _answers[question.id], 
                      activeColor: duckYellow, 
                      onChanged: (v) => setState(() => _answers[question.id] = v)
                    ))
                  
                  else if (question.type == 'MULTIPLE')
                    ...question.options.map((opt) {
                      List<int> selectedList = List<int>.from(_answers[question.id] ?? []);
                      return CheckboxListTile(
                        title: Text(opt.text),
                        value: selectedList.contains(opt.id),
                        activeColor: duckYellow,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              selectedList.add(opt.id);
                            } else {
                              selectedList.remove(opt.id);
                            }
                            _answers[question.id] = selectedList;
                          });
                        },
                      );
                    })

                  else 
                    TextField(
                      onChanged: (v) {
                        setState(() {
                          if (v.trim().isEmpty) _answers.remove(question.id);
                          else _answers[question.id] = v;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Escribe tu respuesta aquí...", 
                        filled: true, 
                        fillColor: Colors.grey.shade50, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                      )
                    )
                ]
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 👁️ PANTALLA 4: RESULTADOS
// =============================================================================
class SurveyResultScreen extends StatefulWidget {
  final Survey survey;
  const SurveyResultScreen({super.key, required this.survey});

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen> {
  Map<String, dynamic> _savedAnswers = {};
  bool isLoading = true;

  @override
  void initState() { 
    super.initState(); 
    _loadUserAnswers(); 
  }

  Future<void> _loadUserAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('survey_answers_${widget.survey.id}');
    
    if (jsonString != null && mounted) {
      setState(() { 
        _savedAnswers = jsonDecode(jsonString); 
        isLoading = false; 
      });
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tus Respuestas"), 
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.survey.questions.length,
            itemBuilder: (context, index) {
              final question = widget.survey.questions[index];
              final dynamic userAnswer = _savedAnswers[question.id.toString()];
              
              String displayText = "Sin respuesta";
              
              if (userAnswer != null) {
                if (question.type == 'SINGLE') {
                  final selectedOption = question.options.firstWhere(
                    (opt) => opt.id == userAnswer, 
                    orElse: () => Option(id: -1, text: "Opción desconocida")
                  );
                  displayText = selectedOption.text;
                } else if (question.type == 'MULTIPLE' && userAnswer is List) {
                  // Mapear IDs a textos de las opciones
                  displayText = question.options
                      .where((opt) => userAnswer.contains(opt.id))
                      .map((opt) => "• ${opt.text}")
                      .join("\n");
                } else { 
                  displayText = userAnswer.toString(); 
                }
              }

              return Card(
                color: Colors.green.shade50, 
                margin: const EdgeInsets.only(bottom: 16), 
                elevation: 2, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text("${index + 1}. ${question.text}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: duckDark)),
                      const SizedBox(height: 8), 
                      const Text("Tu respuesta:", style: TextStyle(fontSize: 12, color: Colors.grey)), 
                      const SizedBox(height: 4),
                      Text(displayText, style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                    ]
                  )
                ),
              );
            },
          ),
    );
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================
Widget _buildEmptyState(String msg, IconData icon) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 60, color: Colors.white70),
    const SizedBox(height: 10),
    Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16))
  ]));
}

Widget _buildSurveyCard(BuildContext context, Survey survey, {required bool isCompleted}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (isCompleted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyResultScreen(survey: survey)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyDetailScreen(survey: survey))).then((val) {
              if (val == true) {
                // Se podría recargar el estado aquí si fuera necesario
              }
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: isCompleted ? Colors.green.withOpacity(0.2) : const Color(0xFFFFD54F).withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: isCompleted ? Colors.green : const Color(0xFFFFD54F), width: 2)), child: Center(child: isCompleted ? const Icon(Icons.check, color: Colors.green, size: 30) : Text(survey.duckAvatar.isNotEmpty ? survey.duckAvatar[0] : "🦆", style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(survey.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))), const SizedBox(height: 5), Text(survey.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 14))])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD54F)),
          ]),
        ),
      ),
    ),
  );
}