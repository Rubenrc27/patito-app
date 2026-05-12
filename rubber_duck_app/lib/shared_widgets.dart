import 'package:flutter/material.dart';
import 'colors.dart';

Widget buildPlaceholder(BuildContext context, String title, VoidCallback onGoToProfile) {
  return Scaffold(
    backgroundColor: backgroundLight,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: borderGray),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryDeepNavy),
            ),
            const SizedBox(height: 16),
            const Text(
              "Para acceder a este contenido y participar en las encuestas, primero debes identificarte.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: neutralGray),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onGoToProfile,
                child: const Text("COMIENZA YA"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
