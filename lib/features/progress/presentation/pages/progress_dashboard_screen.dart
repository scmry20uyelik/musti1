import 'package:flutter/material.dart';
import '../../../../core/network/ai_api_service.dart';
import '../../../home/presentation/widgets/custom_drawer.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _aiService = AiApiService.instance;
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _progressData = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    try {
      // Load progress for all topics
      for (var levelData in CustomDrawer.curriculumData) {
        final level = levelData['level'] as String;
        final topics = levelData['topics'] as List<String>;

        for (var topic in topics) {
          final progress = await _aiService.getUserProgress(topic, level);
          if (progress != null) {
            _progressData['$level-$topic'] = progress;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }
  }

  double _getAccuracy(Map<String, dynamic> progress) {
    final correct = progress['correct_answers'] ?? 0;
    final wrong = progress['wrong_answers'] ?? 0;
    final total = correct + wrong;
    return total > 0 ? correct / total : 0.0;
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlerleme Durumu'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProgress),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progressData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz test çözmediniz',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drawer\'dan bir konu seçip test başlatın',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: CustomDrawer.curriculumData.length,
                itemBuilder: (context, levelIndex) {
                  final levelData = CustomDrawer.curriculumData[levelIndex];
                  final level = levelData['level'] as String;
                  final topics = levelData['topics'] as List<String>;

                  // Check if this level has any progress
                  final hasProgress = topics.any(
                    (topic) => _progressData.containsKey('$level-$topic'),
                  );

                  if (!hasProgress) return const SizedBox.shrink();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: ExpansionTile(
                      title: Text(
                        level,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: topics.map((topic) {
                        final key = '$level-$topic';
                        final progress = _progressData[key];

                        if (progress == null) return const SizedBox.shrink();

                        final accuracy = _getAccuracy(progress);
                        final totalQuestions =
                            (progress['correct_answers'] ?? 0) +
                            (progress['wrong_answers'] ?? 0);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          title: Text(
                            topic,
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: accuracy,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getAccuracyColor(accuracy),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(accuracy * 100).toInt()}%',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getAccuracyColor(accuracy),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${progress['correct_answers']}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${progress['wrong_answers']}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.quiz,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalQuestions soru',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
