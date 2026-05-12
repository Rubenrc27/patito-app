import 'package:flutter/material.dart';
import 'colors.dart';
import 'shared_widgets.dart';

class CreateSurveyScreen extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onGoToProfile;
  const CreateSurveyScreen({super.key, required this.isLoggedIn, required this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return buildPlaceholder(context, "Crear Nueva Encuesta", onGoToProfile);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(title: const Text("Crear Nueva Encuesta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Crear Nueva Encuesta",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryDeepNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              "Diseña tus preguntas, configura los ajustes y despliega a tu equipo.",
              style: TextStyle(fontSize: 16, color: neutralGray),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Detalles de la Encuesta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDeepNavy)),
                    const SizedBox(height: 24),
                    const Text("Título de la Encuesta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    const TextField(
                      decoration: InputDecoration(hintText: "ej., Clima Laboral"),
                    ),
                    const SizedBox(height: 24),
                    const Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    const TextField(
                      maxLines: 3,
                      decoration: InputDecoration(hintText: "Breve contexto para los encuestados..."),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Obligatoria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("Requiere completarse por todos los invitados.", style: TextStyle(fontSize: 12, color: neutralGray)),
                            ],
                          ),
                        ),
                        Switch(value: true, onChanged: (v) {}, activeThumbColor: tertiaryBlue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.rocket_launch),
                label: const Text("Publicar Encuesta"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
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
