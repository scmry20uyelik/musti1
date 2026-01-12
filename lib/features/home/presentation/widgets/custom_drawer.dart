import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../quiz/presentation/pages/quiz_screen.dart';
import '../../../progress/presentation/pages/progress_dashboard_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';
import '../../../about/presentation/pages/about_screen.dart';
import '../providers/selected_topic_provider.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  // Dummy curriculum data - Almanca öğrenme müfredatı
  static final List<Map<String, dynamic>> curriculumData = [
    {
      'level': 'Genel',
      'topics': ['Genel Almanca Sohbet'],
    },
    {
      'level': 'A1.1',
      'topics': [
        'Artikel (der, die, das)',
        'Gramer (Temel)',
        'Tanışma ve Selamlaşma',
        'Sayılar ve Tarihler',
        'Günlük Rutinler',
        'Aile ve Arkadaşlar',
        'Alışveriş - Temel',
        'Renkler ve Nesneler',
      ],
    },
    {
      'level': 'A1.2',
      'topics': [
        'Artikel (Akkusativ)',
        'Gramer (Fiil Çekimleri)',
        'Ev ve Mobilyalar',
        'Yemek ve İçecekler',
        'Şehirde Yön Tarifi',
        'Hobiler ve Boş Zaman',
        'Hava Durumu',
        'Ulaşım Araçları',
      ],
    },
    {
      'level': 'A2.1',
      'topics': [
        'Artikel (Dativ)',
        'Gramer (Geçmiş Zaman)',
        'Seyahat ve Tatil',
        'Sağlık ve Hastalıklar',
        'İş ve Meslek',
        'Teknoloji Kullanımı',
        'Kıyafetler ve Moda',
        'Davetler ve Kutlamalar',
      ],
    },
    {
      'level': 'A2.2',
      'topics': [
        'Artikel (Genitiv)',
        'Gramer (Gelecek Zaman)',
        'Eğitim Sistemi',
        'Kültür ve Gelenekler',
        'Spor ve Aktiviteler',
        'Medya ve Haberler',
        'Çevre ve Doğa',
        'Duygular ve İfadeler',
      ],
    },
    {
      'level': 'B1.1',
      'topics': [
        'Artikel (İleri Kullanım)',
        'Gramer (Konjunktiv I)',
        'İş Görüşmeleri',
        'Formal Yazışmalar',
        'Toplantı ve Sunum',
        'Ekonomi ve Finans',
        'Politika ve Toplum',
        'Kişisel Gelişim',
      ],
    },
    {
      'level': 'B1.2',
      'topics': [
        'Artikel (Özel Durumlar)',
        'Gramer (Konjunktiv II)',
        'Bilimsel Metinler',
        'Edebiyat ve Sanat',
        'Tarih ve Coğrafya',
        'Felsefe ve Etik',
        'Sosyal Medya',
        'İlişkiler ve Toplum',
      ],
    },
    {
      'level': 'B2.1',
      'topics': [
        'Artikel (Nüans ve Ton)',
        'Gramer (Passiv Formen)',
        'İleri Okuma Stratejileri',
        'Argümantasyon ve Tartışma',
        'Akademik Yazım',
        'Araştırma Metodları',
        'Eleştirel Düşünme',
        'Profesyonel İletişim',
      ],
    },
    {
      'level': 'B2.2',
      'topics': [
        'Artikel (Kompleks Yapılar)',
        'Gramer (İleri Seviye)',
        'Kompleks Dilbilgisi',
        'İleri Seviye Kelime',
        'Nüans ve İfade',
        'Profesyonel Almanca',
        'Sınav Hazırlık (Goethe)',
        'İş Dünyası Almancası',
      ],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF8B5E3C),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: curriculumData.length,
                itemBuilder: (context, index) {
                  return _buildLevelExpansionTile(
                    context,
                    ref,
                    curriculumData[index],
                  );
                },
              ),
            ),
            _buildDrawerFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, size: 40, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 16),
              Text(
                'Almanca AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Almanca Öğrenme',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
        ],
      ),
    );
  }

  Widget _buildLevelExpansionTile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> levelData,
  ) {
    final level = levelData['level'] as String;
    final topics = levelData['topics'] as List<String>;
    final selectedTopic = ref.watch(selectedTopicProvider);

    // Premium renk paleti - her seviye için özel renkler
    final levelColors = {
      'Genel': {
        'bg': const Color(0xFFD4AF37),
        'text': const Color(0xFFFFF8DC),
      }, // Altın
      'A1.1': {
        'bg': const Color(0xFFD4824A),
        'text': const Color(0xFFFFE4CC),
      }, // Turuncu
      'A1.2': {
        'bg': const Color(0xFF6B9B7F),
        'text': const Color(0xFFD4F1E8),
      }, // Yeşil
      'A2.1': {
        'bg': const Color(0xFF5D8AA8),
        'text': const Color(0xFFD4E8F0),
      }, // Turkuaz
      'A2.2': {
        'bg': const Color(0xFF9B7EBD),
        'text': const Color(0xFFEDE4F5),
      }, // Lavanta
      'B1.1': {
        'bg': const Color(0xFFB85342),
        'text': const Color(0xFFFFE4E0),
      }, // Bakır
      'B1.2': {
        'bg': const Color(0xFF50C878),
        'text': const Color(0xFFE0F8E8),
      }, // Zümrüt
      'B2.1': {
        'bg': const Color(0xFF8B7355),
        'text': const Color(0xFFE8DED0),
      }, // Bronz
      'B2.2': {
        'bg': const Color(0xFFCC5500),
        'text': const Color(0xFFFFE8D4),
      }, // Terracotta
    };

    final colors =
        levelColors[level] ??
        {'bg': const Color(0xFFD4824A), 'text': const Color(0xFFD4AF37)};
    final bgColor = colors['bg'] as Color;
    final textColor = colors['text'] as Color;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          level,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, bgColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              level.split('.')[0],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white.withValues(alpha: 0.7),
        children: topics.map((topic) {
          final isSelected =
              selectedTopic?.level == level &&
              selectedTopic?.topicTitle == topic;

          return ListTile(
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: Text(
              topic,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : Colors.white.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Test button
                IconButton(
                  icon: const Icon(Icons.school_outlined, size: 20),
                  color: Colors.white.withValues(alpha: 0.7),
                  tooltip: 'Test',
                  onPressed: () {
                    debugPrint('🔔 Drawer Test pressed: level=$level topic=$topic');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            QuizScreen(levelName: level, topicName: topic),
                      ),
                    );
                  },
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
              ],
            ),
            onTap: () {
              ref.read(selectedTopicProvider.notifier).state = SelectedTopic(
                level: level,
                topicTitle: topic,
              );
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.white70),
            title: Text(
              'İlerleme Durumu',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProgressDashboardScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: Text(
              'Ayarlar',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white70),
            title: Text(
              'Hakkında',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: Text(
              'Çıkış Yap',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
