import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../quiz/presentation/pages/quiz_screen.dart';
import '../../../vocabulary/presentation/pages/vocabulary_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';
import '../../../../features/home/presentation/providers/selected_topic_provider.dart';
import '../../../../features/home/presentation/widgets/custom_drawer.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // A1.1 seviyesini varsayılan olarak göster
    final currentLevel = CustomDrawer.curriculumData[1]; // A1.1

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Dersler',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Seviye bilgisi ve progress
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentLevel['level']} Seviye - Başlangıç',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.66, // 10/15
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '10/15 Tamamlandı',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Kategori kartları listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: (currentLevel['topics'] as List).length,
                itemBuilder: (context, index) {
                  final topic = (currentLevel['topics'] as List)[index];
                  final icons = [
                    Icons.checklist_rtl,
                    Icons.chat_bubble_outline,
                    Icons.wb_sunny_outlined,
                    Icons.menu_book,
                    Icons.headphones,
                  ];
                  final colors = [
                    const Color(0xFFD4824A), // Turuncu
                    const Color(0xFFB85342), // Kırmızı
                    const Color(0xFF6B9B7F), // Yeşil
                    const Color(0xFF8B5E3C), // Kahverengi
                    const Color(0xFFD4AF37), // Altın
                  ];

                  return _CategoryCard(
                    title: topic,
                    icon: icons[index % icons.length],
                    color: colors[index % colors.length],
                    progress: '${(index + 1) * 2}/12 Tamamlandı',
                    isCompleted:
                        index < 1, // İlk kategori tamamlanmış gibi göster
                    onTap: () {
                      ref
                          .read(selectedTopicProvider.notifier)
                          .state = SelectedTopic(
                        level: currentLevel['level'],
                        topicTitle: topic,
                      );

                      // Chat ekranına git
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                    onQuizTap: () {
                      ref
                          .read(selectedTopicProvider.notifier)
                          .state = SelectedTopic(
                        level: currentLevel['level'],
                        topicTitle: topic,
                      );

                      // Quiz ekranına git
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            levelName: currentLevel['level'],
                            topicName: topic,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Alt menü butonları
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomButton(
                    icon: Icons.book_outlined,
                    label: 'Kelime Havuzu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VocabularyScreen(),
                        ),
                      );
                    },
                  ),
                  _BottomButton(
                    icon: Icons.headphones,
                    label: 'Dinleme',
                    onTap: () {
                      // TODO: Dinleme ekranı
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kategori kartı widget'ı
class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String progress;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onQuizTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.progress,
    required this.isCompleted,
    required this.onTap,
    required this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // İkon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),

                // Başlık ve progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCompleted)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B9B7F),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Oklar
                Row(
                  children: [
                    IconButton(
                      onPressed: onQuizTap,
                      icon: Icon(Icons.quiz_outlined, color: color),
                      tooltip: 'Test',
                    ),
                    Icon(Icons.arrow_forward_ios, color: color, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alt menü buton widget'ı
class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
