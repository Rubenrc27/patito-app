// 1. MODELO SURVEY (ENCUESTA)
class Survey {
  final int id;
  final String title;
  final String description;
  final String duckAvatar; // Campo decorativo frontend
  final List<Question> questions;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.duckAvatar,
    required this.questions,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      // PROTECCIÓN 1: Si id es nulo, ponemos 0
      id: json['id'] ?? 0,
      
      // PROTECCIÓN 2: Si title es nulo, ponemos texto por defecto
      title: json['title'] ?? 'Sin título',
      
      description: json['description'] ?? '',
      
      // PROTECCIÓN 3: Si el backend no envía avatar, usamos el clásico
      duckAvatar: json['duckAvatar'] ?? 'CLASSIC',
      
      // PROTECCIÓN 4: Lista segura. Si es null, usa lista vacía []
      questions: (json['questions'] as List<dynamic>?)
          ?.map((i) => Question.fromJson(i))
          .toList() ?? [],
    );
  }
}

// 2. MODELO QUESTION (PREGUNTA)
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
    return Question(
      id: json['id'] ?? 0,
      
      // OJO AQUÍ: Tu backend Java seguramente lo llama 'text', pero por si acaso
      // usamos 'questionText' como respaldo.
      text: json['text'] ?? json['questionText'] ?? 'Pregunta sin texto',
      
      // ¡IMPORTANTE! En Spring Boot el campo se llama 'questionType', no 'type'.
      // Aquí buscamos ambos por si acaso.
      type: json['questionType'] ?? json['type'] ?? 'SINGLE',
      
      options: (json['options'] as List<dynamic>?)
          ?.map((i) => Option.fromJson(i))
          .toList() ?? [],
    );
  }
}

// 3. MODELO OPTION (OPCIÓN)
class Option {
  final int id;
  final String text;

  Option({required this.id, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'] ?? 0,
      
      // CRÍTICO: En el error anterior vimos que Java usaba 'optionText' o 'text'.
      // Aquí probamos los dos para que no falle nunca.
      text: json['text'] ?? json['optionText'] ?? '',
    );
  }
}