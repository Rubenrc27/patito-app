import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'models.dart';
import 'api_config.dart';
import 'shared_widgets.dart';

// =============================================================================
// 🌊 PANTALLA 1: ESTANQUE (FEED)
// =============================================================================
class EstanqueScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback onGoToProfile;
  const EstanqueScreen({super.key, required this.isLoggedIn, required this.onGoToProfile});

  @override
  State<EstanqueScreen> createState() => _EstanqueScreenState();
}

class _EstanqueScreenState extends State<EstanqueScreen> {
  List<Survey> surveys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadData();
    } else {
      isLoading = false;
    }
  }

  @override
  void didUpdateWidget(EstanqueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn && !oldWidget.isLoggedIn) {
      setState(() => isLoading = true);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;
    final String? token = prefs.getString('jwt_token');

    try {
      final urlAll = Uri.parse(ApiConfig.surveysUrl);
      final urlMine = Uri.parse('${ApiConfig.surveysUrl}/mis-encuestas?userId=$userId');

      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
      };

      debugPrint('Cargando encuestas para userId: $userId');
      
      // Cargamos por separado para que si falla una, la otra funcione
      final responseAll = await http.get(urlAll, headers: headers);
      debugPrint('Status All: ${responseAll.statusCode}');

      List<dynamic> allJson = [];
      if (responseAll.statusCode == 200) {
        allJson = json.decode(utf8.decode(responseAll.bodyBytes));
      }

      List<dynamic> mineJson = [];
      try {
        final responseMine = await http.get(urlMine, headers: headers);
        debugPrint('Status Mine: ${responseMine.statusCode}');
        if (responseMine.statusCode == 200) {
          mineJson = json.decode(utf8.decode(responseMine.bodyBytes));
        }
      } catch (e) {
        debugPrint('Error cargando mis-encuestas: $e');
      }

      debugPrint('JSON All length: ${allJson.length}');
      debugPrint('JSON Mine length: ${mineJson.length}');
      
      final Set<int> myCompletedIds = mineJson.map((e) => (e['id'] as num).toInt()).toSet();

      if (mounted) {
        setState(() {
          try {
            surveys = allJson
                .map((e) => Survey.fromJson(e))
                .where((s) => !myCompletedIds.contains(s.id))
                .toList();
            debugPrint('Encuestas finales en lista: ${surveys.length}');
          } catch (e) {
            debugPrint('Error parseando encuestas: $e');
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error en la conexión o proceso: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) return buildPlaceholder(context, "Tu Estanque de Encuestas", widget.onGoToProfile);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("Tu Estanque de Encuestas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _loadData();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tu Estanque",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryDeepNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Completa tus encuestas pendientes para compartir tu opinión.",
                            style: TextStyle(fontSize: 16, color: neutralGray),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  surveys.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState("¡Estanque limpio!", Icons.done_all),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              mainAxisExtent: 260,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildSurveyCard(
                                context, 
                                surveys[index], 
                                isCompleted: false,
                                onRefresh: () {
                                  setState(() => isLoading = true);
                                  _loadData();
                                }
                              ),
                              childCount: surveys.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }
}

// =============================================================================
// ✅ PANTALLA 2: MIS ENCUESTAS (COMPLETED)
// =============================================================================
class MisEncuestasScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback onGoToProfile;
  const MisEncuestasScreen({super.key, required this.isLoggedIn, required this.onGoToProfile});

  @override
  State<MisEncuestasScreen> createState() => _MisEncuestasScreenState();
}

class _MisEncuestasScreenState extends State<MisEncuestasScreen> {
  List<Survey> surveys = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadData();
    } else {
      isLoading = false;
    }
  }

  @override
  void didUpdateWidget(MisEncuestasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn && !oldWidget.isLoggedIn) {
      setState(() => isLoading = true);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;
    final String? token = prefs.getString('jwt_token');
    
    final url = Uri.parse('${ApiConfig.surveysUrl}/mis-encuestas?userId=$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
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
    if (!widget.isLoggedIn) return buildPlaceholder(context, "Encuestas Completadas", widget.onGoToProfile);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("Completed Surveys"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : surveys.isEmpty
              ? _buildEmptyState("Sin encuestas completadas.", Icons.assignment_late)
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          mainAxisExtent: 260,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildSurveyCard(context, surveys[index], isCompleted: true, onRefresh: _loadData),
                          childCount: surveys.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
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
    final String? token = prefs.getString('jwt_token');

    List<Map<String, dynamic>> payload = [];
    
    _answers.forEach((questionId, value) {
      if (value is List) {
        for (var optionId in value) {
          payload.add({
            "questionId": questionId, 
            "optionId": optionId,
            "surveyId": widget.survey.id
          });
        }
      } else if (value is int) {
        payload.add({
          "questionId": questionId, 
          "optionId": value,
          "surveyId": widget.survey.id
        });
      } else if (value is String && value.trim().isNotEmpty) {
        payload.add({
          "questionId": questionId, 
          "text": value,
          "surveyId": widget.survey.id
        });
      }
    });

    final url = Uri.parse('${ApiConfig.surveysUrl}/submit?userId=$userId');

    try {
      final response = await http.post(
        url, 
        headers: {
          "Content-Type": "application/json",
          if (token != null) 'Authorization': 'Bearer $token',
        }, 
        body: jsonEncode(payload)
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        Map<String, dynamic> answersToSave = _answers.map((k, v) => MapEntry(k.toString(), v));
        await prefs.setString('survey_answers_${widget.survey.id}', jsonEncode(answersToSave));
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Enviado con éxito!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true); 
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}'))
        );
        }
      }
    } catch (e) { 
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión'))
      );
      } 
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text(widget.survey.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: widget.survey.questions.length + 1,
        itemBuilder: (context, index) {
          
          if (index == widget.survey.questions.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 48), 
              child: SizedBox(
                height: 56, 
                child: ElevatedButton(
                  onPressed: (isSubmitting || _answers.isEmpty) ? null : submitAnswers, 
                  child: isSubmitting 
                    ? const CircularProgressIndicator(color: primaryDeepNavy)
                    : const Text("SUBMIT RESPONSES")
                )
              )
            );
          }

          final question = widget.survey.questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(24), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text("${index + 1}. ${question.text}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
                  const SizedBox(height: 16),
                  
                  if (question.type == 'SINGLE') 
                    ...question.options.map((opt) => RadioListTile<int>(
                      title: Text(opt.text), 
                      value: opt.id, 
                      // ignore: deprecated_member_use
                      groupValue: _answers[question.id], 
                      activeColor: tertiaryBlue, 
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => _answers[question.id] = v)
                    ))
                  
                  else if (question.type == 'MULTIPLE')
                    ...question.options.map((opt) {
                      List<int> selectedList = List<int>.from(_answers[question.id] ?? []);
                      return CheckboxListTile(
                        title: Text(opt.text),
                        value: selectedList.contains(opt.id),
                        activeColor: tertiaryBlue,
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
                          if (v.trim().isEmpty) {
                            _answers.remove(question.id);
                          } else {
                            _answers[question.id] = v;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Escribe tu respuesta aquí...", 
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
  Map<String, dynamic>? _stats;
  bool isLoading = true;

  @override
  void initState() { 
    super.initState(); 
    _loadStats(); 
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.surveysUrl}/${widget.survey.id}/stats'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = jsonDecode(utf8.decode(response.bodyBytes));
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("Estadísticas de la Encuesta"), 
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _stats == null 
          ? _buildEmptyState("No hay datos disponibles", Icons.bar_chart)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 32),
                  const Text("Resultados por Pregunta", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
                  const SizedBox(height: 16),
                  ...(_stats!['questions'] as List).map((q) => _buildQuestionStatCard(q)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48, color: tertiaryBlue),
            const SizedBox(height: 16),
            Text(
              "${_stats!['totalParticipants']}",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryDeepNavy),
            ),
            const Text("Participantes totales", style: TextStyle(color: neutralGray)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Estos datos son totalmente anónimos y muestran la tendencia global de las respuestas.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: neutralGray, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStatCard(Map<String, dynamic> q) {
    List<dynamic>? options = q['options'];
    int totalQ = 0;
    if (options != null) {
      for (var opt in options) {
        totalQ += (opt['count'] as num).toInt();
      }
    } else {
      totalQ = (q['totalAnswers'] as num).toInt();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q['text'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryDeepNavy),
            ),
            const SizedBox(height: 20),
            if (options != null && totalQ > 0)
              ...options.map((opt) {
                double percent = totalQ > 0 ? (opt['count'] / totalQ) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(opt['text'], style: const TextStyle(fontSize: 14))),
                          Text("${(percent * 100).toStringAsFixed(1)}% (${opt['count']})", 
                               style: const TextStyle(fontWeight: FontWeight.bold, color: tertiaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: borderGray.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percent,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: tertiaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
            else if (q['type'] == 'OPEN')
              Text("Se han recibido $totalQ respuestas de texto libre.", 
                   style: const TextStyle(color: neutralGray, fontStyle: FontStyle.italic))
            else
              const Text("Sin respuestas aún", style: TextStyle(color: neutralGray)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================
Widget _buildEmptyState(String msg, IconData icon) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 64, color: borderGray),
    const SizedBox(height: 16),
    Text(msg, style: const TextStyle(color: neutralGray, fontSize: 18))
  ]));
}

Widget _buildSurveyCard(BuildContext context, Survey survey, {required bool isCompleted, VoidCallback? onRefresh}) {
  final isMandatory = survey.title.toLowerCase().contains("obligatoria") || survey.id % 3 == 0;
  
  return Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () {
        if (isCompleted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyResultScreen(survey: survey)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyDetailScreen(survey: survey))).then((val) {
            if (val == true && onRefresh != null) {
              onRefresh();
            }
          });
        }
      },
      child: Stack(
        children: [
          if (!isCompleted && isMandatory)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: errorRed),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: borderGray,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: neutralGray),
                            SizedBox(width: 4),
                            Text("Completada", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: neutralGray)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMandatory ? errorRed.withValues(alpha: 0.1) : tertiaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(isMandatory ? Icons.priority_high : Icons.info_outline, size: 14, color: isMandatory ? errorRed : tertiaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              isMandatory ? "Obligatoria" : "Opcional",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMandatory ? errorRed : tertiaryBlue),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: neutralGray),
                        const SizedBox(width: 4),
                        Text(isCompleted ? "1 Oct" : "15 min", style: const TextStyle(fontSize: 10, color: neutralGray)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  survey.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? neutralGray : primaryDeepNavy,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  survey.description,
                  style: const TextStyle(fontSize: 14, color: neutralGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                const Divider(color: borderGray),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Límite: 15 Oct", style: TextStyle(fontSize: 12, color: neutralGray)),
                    if (!isCompleted)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyDetailScreen(survey: survey)));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: isMandatory ? secondaryYellow : Colors.white,
                          foregroundColor: primaryDeepNavy,
                          side: isMandatory ? null : const BorderSide(color: borderGray),
                        ),
                        child: const Row(
                          children: [
                            Text("Empezar", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      )
                    else
                      const Text("Puntos: 50", style: TextStyle(fontSize: 12, color: neutralGray)),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              color: Colors.white.withValues(alpha: 0.4),
            ),
        ],
      ),
    ),
  );
}

