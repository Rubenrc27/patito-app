import 'dart:convert'; // Para convertir el JSON a objetos
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Nuestra librería de conexión

// 1. EL PUNTO DE ENTRADA
void main() {
  runApp(const MyApp());
}

// 2. CONFIGURACIÓN DE LA APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubber Duck Surveys',
      theme: ThemeData(
        primarySwatch: Colors.yellow, // Color temático Patito
        useMaterial3: true,
      ),
      home: const SurveyListScreen(),
    );
  }
}

// 3. EL MODELO DE DATOS (Copia de tu Entidad Java)
class Survey {
  final int id;
  final String title;
  final String description;
  final String duckAvatar;
  final List<Question> questions; // <--- ¡NUEVO!

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.duckAvatar,
    required this.questions, // <--- ¡NUEVO!
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    // Truco para convertir la lista de JSON en lista de Objetos Question
    var list = json['questions'] as List? ?? []; // Si viene null, lista vacía
    List<Question> questionsList = list.map((i) => Question.fromJson(i)).toList();

    return Survey(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      duckAvatar: json['duckAvatar'] ?? 'CLASSIC',
      questions: questionsList, // <--- ¡NUEVO!
    );
  }
}

// 4. LA PANTALLA PRINCIPAL
class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({super.key});

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  List<Survey> surveys = [];
  bool isLoading = true; // Para mostrar la ruedita cargando

  @override
  void initState() {
    super.initState();
    fetchSurveys(); // Al nacer la pantalla, pedimos datos
  }

  Future<void> fetchSurveys() async {
    // TRUCO DEL ALMENDRUCO: 
    // Android Emulator no conoce "localhost". 
    // Para el emulador, tu PC es "10.0.2.2".
    final url = Uri.parse('http://localhost:8080/api/surveys'); 
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes)); // utf8 para las tildes
        setState(() {
          surveys = data.map((item) => Survey.fromJson(item)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error conectando con Java: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encuestas Patito 🦆')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: surveys.length,
              itemBuilder: (context, index) {
                final survey = surveys[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.yellow[200],
                      child: Text(survey.duckAvatar[0]), 
                    ),
                    title: Text(survey.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(survey.description),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    
                    // --- AQUÍ ESTÁ LA MAGIA ---
                    onTap: () {
                      // Navegar a la pantalla de detalle
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurveyDetailScreen(survey: survey),
                        ),
                      );
                    },
                    // --------------------------
                  ),
                );
              },
            ),
    );
  }
}

// Clase para las Preguntas
class Question {
  final int id;
  final String text;
  final String type;
  final List<Option> options;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // 1. Extraemos la lista con seguridad. Si es null, usamos lista vacía [].
    var list = (json['options'] as List?) ?? []; 
    
    // 2. Convertimos cada item de la lista en un objeto Option
    List<Option> optionsList = list.map((i) => Option.fromJson(i)).toList();

    return Question(
      id: json['id'],
      text: json['text'],
      type: json['type'],
      options: optionsList, // Ahora seguro que no es null
    );
  }
}
class Option {
  final int id;
  final String text;

  Option({required this.id, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      text: json['text'],
    );
  }
}

// PANTALLA DE DETALLE DE LA ENCUESTA
// PANTALLA DE DETALLE (Ahora con Memoria/Estado)
class SurveyDetailScreen extends StatefulWidget {
  final Survey survey;

  const SurveyDetailScreen({super.key, required this.survey});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  // 1. LA LIBRETA: Aquí guardamos las respuestas.
  // Clave (int) = ID de la pregunta.
  // Valor (dynamic) = ID de la opción elegida o Texto escrito.
  final Map<int, dynamic> _answers = {};

  Future<void> submitAnswers() async {
    // 1. Preparar los datos (Convertir la libreta _answers a una lista bonita para Java)
    List<Map<String, dynamic>> payload = [];

    _answers.forEach((questionId, value) {
      Map<String, dynamic> answerData = {
        "questionId": questionId,
      };

      // Detectamos si es una Opción (número) o Texto (String)
      if (value is int) {
        answerData["optionId"] = value; // Es una selección (SINGLE)
      } else if (value is String) {
        answerData["text"] = value;     // Es una respuesta abierta (OPEN)
      }

      payload.add(answerData);
    });

    // 2. Enviar al Servidor
    // ¡OJO! Usa la misma IP que te funcionó antes (localhost o 192.168...)
    // Si usaste 'adb reverse', usa localhost. Si no, tu IP.
    final url = Uri.parse('http://localhost:8080/api/surveys/submit'); 

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"}, // Importante: Decirle que es JSON
        body: jsonEncode(payload), // Convertimos la lista a texto JSON
      );

      if (response.statusCode == 200) {
        // 3. Éxito: Volver atrás y felicitar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Encuesta enviada! Gracias 🦆')),
          );
          Navigator.pop(context); // Cierra la pantalla
        }
      } else {
        print("Error servidor: ${response.body}");
        throw Exception('Falló el envío');
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.survey.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Icon(Icons.cruelty_free, size: 60, color: Colors.orange),
            ),
            const SizedBox(height: 10),
            Text(
              "Responde para ganar puntos:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),

            Expanded(
              child: ListView.builder(
                itemCount: widget.survey.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.survey.questions[index];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${question.text}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // LOGICA PARA PREGUNTAS DE SELECCIÓN (SINGLE)
                          if (question.type == 'SINGLE')
                            ...question.options.map((option) {
                              return RadioListTile<int>(
                                title: Text(option.text),
                                value: option.id,
                                // Aquí está la magia: miramos en la libreta qué opción está marcada
                                groupValue: _answers[question.id], 
                                activeColor: Colors.orange,
                                onChanged: (value) {
                                  setState(() {
                                    // Guardamos la respuesta en la libreta
                                    _answers[question.id] = value;
                                  });
                                },
                              );
                            })

                          // LÓGICA PARA PREGUNTAS ABIERTAS (OPEN)
                          else if (question.type == 'OPEN')
                            TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Escribe aquí...',
                              ),
                              onChanged: (text) {
                                // Guardamos lo que escribe el usuario
                                _answers[question.id] = text;
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // BOTÓN DE ENVIAR (Solo decorativo de momento)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, 
                  foregroundColor: Colors.white
                ),
                onPressed: () {
                  // 1. Validación: Si no ha marcado nada, le regañamos suavemente
                  if (_answers.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Por favor, marca alguna respuesta antes!')),
                    );
                    return; // Cortamos aquí para no enviar nada vacío
                  }

                  // 2. ¡ENVIAR DE VERDAD! Llamamos a la función que conecta con Java
                  submitAnswers();
                },
                child: const Text("ENVIAR RESPUESTAS"),
              ),
            )
          ],
        ),
      ),
    );
  }
}