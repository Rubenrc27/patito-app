import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'models.dart';

// =============================================================================
// 🌊 PANTALLA 1: ESTANQUE (Se recarga cada vez que entras)
// =============================================================================
class EstanqueScreen extends StatefulWidget {
  const EstanqueScreen({super.key});

  @override
  State<EstanqueScreen> createState() => _EstanqueScreenState();
}

class _EstanqueScreenState extends State<EstanqueScreen> { // <--- YA NO HAY MIXIN
  List<Survey> surveys = [];
  bool isLoading = true;

  // <--- YA NO HAY wantKeepAlive NI super.build

  @override
  void initState() {
    super.initState();
    _loadData(); // Se ejecuta SIEMPRE que abres esta pestaña
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    try {
      final urlAll = Uri.parse('http://127.0.0.1:8080/api/surveys');
      final urlMine = Uri.parse('http://127.0.0.1:8080/api/surveys/mis-encuestas?userId=$userId');

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
              ? _buildEmptyState("¡Estanque limpio! No hay nuevas encuestas.", Icons.done_all)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: surveys.length,
                  itemBuilder: (context, index) => _buildSurveyCard(context, surveys[index], isCompleted: false),
                ),
    );
  }
}

// =============================================================================
// ✅ PANTALLA 2: MIS ENCUESTAS (Se recarga cada vez que entras)
// =============================================================================
class MisEncuestasScreen extends StatefulWidget {
  const MisEncuestasScreen({super.key});

  @override
  State<MisEncuestasScreen> createState() => _MisEncuestasScreenState();
}

class _MisEncuestasScreenState extends State<MisEncuestasScreen> { // <--- YA NO HAY MIXIN
  List<Survey> surveys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Se ejecuta SIEMPRE que abres esta pestaña
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;
    
    final url = Uri.parse('http://127.0.0.1:8080/api/surveys/mis-encuestas?userId=$userId');

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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => isLoading = true); _loadData(); })
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : surveys.isEmpty
              ? _buildEmptyState("Aún no has completado ninguna encuesta.", Icons.assignment_late)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: surveys.length,
                  itemBuilder: (context, index) => _buildSurveyCard(context, surveys[index], isCompleted: true),
                ),
    );
  }
}

// =============================================================================
// WIDGETS COMUNES (SIN CAMBIOS)
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
        onTap: () async {
          if (isCompleted) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyResultScreen(survey: survey)));
          } else {
             // 🦆 TRUCO: Cuando vuelves de responder, si esperamos 'true', podemos recargar manualmente
             // aunque ahora al cambiar de pestaña ya se hace solo.
             final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyDetailScreen(survey: survey)));
             if (result == true) {
               // Podríamos forzar setState, pero al cambiar de pestaña se arregla solo.
             }
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
  final Map<int, dynamic> _answers = {}; // Guardamos las respuestas aquí
  bool isSubmitting = false;

  Future<void> submitAnswers() async {
    setState(() => isSubmitting = true);
    
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    // 1. Preparamos el JSON para el servidor
    List<Map<String, dynamic>> payload = [];
    _answers.forEach((questionId, value) {
      Map<String, dynamic> answerData = {"questionId": questionId};
      if (value is int) {
        answerData["optionId"] = value; // Es una opción (Radio)
      } else if (value is String) {
        answerData["text"] = value;     // Es texto
      }
      payload.add(answerData);
    });

    // 2. URL con userId (IP 127.0.0.1 por tu ADB)
    final url = Uri.parse('http://127.0.0.1:8080/api/surveys/submit?userId=$userId');

    try {
      final response = await http.post(
        url, 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(payload)
      );

      if (response.statusCode == 200 && mounted) {
        // 3. ¡ÉXITO! Guardamos copia local para poder verla luego en "Mis Encuestas"
        // (Esto es un truco para no tener que pedirle las respuestas detalladas al servidor aún)
        Map<String, dynamic> answersToSave = _answers.map((k, v) => MapEntry(k.toString(), v));
        await prefs.setString('survey_answers_${widget.survey.id}', jsonEncode(answersToSave));
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Enviado! 🦆'), backgroundColor: Colors.green));
        
        // Devolvemos "true" para que la pantalla anterior sepa que hemos terminado
        Navigator.pop(context, true); 
      } else {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error del servidor: ${response.statusCode}')));
      }
    } catch (e) { 
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); 
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
        itemCount: widget.survey.questions.length + 1, // +1 para el botón de enviar
        itemBuilder: (context, index) {
          
          // BOTÓN ENVIAR (Último elemento)
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

          // PREGUNTAS
          final question = widget.survey.questions[index];
          return Card(
            color: Colors.white, 
            elevation: 3, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16), 
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${index + 1}. ${question.text}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: duckDark)),
                  const SizedBox(height: 10),
                  
                  // Si es Selección Única (Radio)
                  if (question.type == 'SINGLE') 
                    ...question.options.map((opt) => RadioListTile<int>(
                      title: Text(opt.text), 
                      value: opt.id, 
                      groupValue: _answers[question.id], 
                      activeColor: duckYellow, 
                      onChanged: (v) => setState(() => _answers[question.id] = v)
                    ))
                  
                  // Si es Texto Libre
                  else 
                    TextField(
                      onChanged: (v) => _answers[question.id] = v, 
                      decoration: InputDecoration(
                        hintText: "Escribe tu respuesta aquí...", 
                        filled: true, 
                        fillColor: Colors.grey.shade50, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                      )
                    )
                ])),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 👁️ PANTALLA 4: RESULTADOS (Solo Lectura)
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
  void initState() { super.initState(); _loadUserAnswers(); }

  // Cargamos las respuestas que guardamos en local al enviar
  Future<void> _loadUserAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('survey_answers_${widget.survey.id}');
    
    if (jsonString != null && mounted) {
      setState(() { 
        _savedAnswers = jsonDecode(jsonString); 
        isLoading = false; 
      });
    } else {
      setState(() => isLoading = false);
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
              
              String displayText = "Sin respuesta (o no guardada)";
              
              if (userAnswer != null) {
                if (question.type == 'SINGLE') {
                  // Buscamos el texto de la opción seleccionada
                  final selectedOption = question.options.firstWhere(
                    (opt) => opt.id == userAnswer, 
                    orElse: () => Option(id: -1, text: "Opción desconocida")
                  );
                  displayText = selectedOption.text;
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
                      Text(displayText, style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                    ]
                  )
                ),
              );
            },
          ),
    );
  }
}