import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.school,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Mirmir',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Almanca Öğrenme Uygulaması',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text('Versiyon 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Mirmir, yapay zeka destekli Almanca öğrenme deneyimi sunan modern bir uygulamadır. '
              'A1.1\'den B2.2\'ye kadar tüm seviyelerde interaktif sohbet ve adaptif testlerle '
              'Almanca öğrenmenizi kolaylaştırır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              '© 2026 Mirmir App',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
