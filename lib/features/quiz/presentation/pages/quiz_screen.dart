import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/ai_api_service.dart';

class QuizScreen extends StatefulWidget {
  final String levelName;
  final String topicName;

  const QuizScreen({
    super.key,
    required this.levelName,
    required this.topicName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _aiService = AiApiService.instance;

  bool _isLoading = true;
  bool _showExplanation = false;
  bool _showTranslation = false;
  String? _selectedAnswer;
  Map<String, dynamic>? _currentQuiz;
  int _correctCount = 0;
  int _totalQuestions = 0;
  String? _currentDifficulty;
  final Set<String> _askedQuestions = {}; // Sorulan soruları takip et

  @override
  void initState() {
    super.initState();
    debugPrint('➡️ QuizScreen opened for level=${widget.levelName}, topic=${widget.topicName}');
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _showExplanation = false;
      _showTranslation = false;
      _selectedAnswer = null;
    });

    try {
      final quizData = await _aiService.getAdaptiveQuiz(
        widget.topicName,
        widget.levelName,
      );

      // Aynı soru tekrar geldiyse, yeniden yükle
      final question = quizData['question'] as String;
      if (_askedQuestions.contains(question) && _askedQuestions.length < 20) {
        // 20'den az soru sorulduysa tekrar dene
        await _loadQuiz();
        return;
      }

      _askedQuestions.add(question);

      setState(() {
        _currentQuiz = quizData;
        _currentDifficulty = quizData['difficulty'] ?? 'medium';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Soru yüklenemedi: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: () => _loadQuiz(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _currentQuiz == null) return;

    final correctAnswer = (_currentQuiz!['correct_answer'] as String).trim();
    final selectedAnswer = _selectedAnswer!.trim();
    final isCorrect = selectedAnswer == correctAnswer;

    setState(() {
      _showExplanation = true;
      _totalQuestions++;
      if (isCorrect) _correctCount++;
    });

    // Save result to database
    try {
      await _aiService.saveQuizResult(
        topic: widget.topicName,
        level: widget.levelName,
        question: _currentQuiz!['question'],
        userAnswer: _selectedAnswer!,
        correctAnswer: correctAnswer,
        isCorrect: isCorrect,
        difficulty: _currentDifficulty ?? 'medium',
      );
    } catch (e) {
      // Kayıt hatası olsa bile devam et, kullanıcıyı rahatsız etme
      debugPrint('Quiz kaydetme hatası: $e');
    }
  }

  void _nextQuestion() {
    _loadQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quiz Zamanı',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_correctCount / $_totalQuestions',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentQuiz == null
          ? const Center(child: Text('Soru yüklenemedi'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Progress indicator
                        if (_totalQuestions > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: LinearProgressIndicator(
                              value: _correctCount / _totalQuestions,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _correctCount / _totalQuestions > 0.8
                                    ? Colors.green[600]!
                                    : _correctCount / _totalQuestions > 0.5
                                    ? Colors.orange[600]!
                                    : Colors.red[600]!,
                              ),
                            ),
                          ),

                        // Question
                        Card(
                          elevation: 2,
                          color: theme.colorScheme.surfaceContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  _currentQuiz!['question'],
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton.filled(
                                      onPressed: () {
                                        setState(() {
                                          _showTranslation = !_showTranslation;
                                        });
                                      },
                                      icon: Icon(
                                        _showTranslation
                                            ? Icons.translate_outlined
                                            : Icons.translate,
                                        size: 20,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        foregroundColor: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _showTranslation
                                          ? 'Türçe gizle'
                                          : 'Türçe göster',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                if (_showTranslation &&
                                    _currentQuiz!['question_turkish'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _currentQuiz!['question_turkish'],
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontStyle: FontStyle.italic,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Options
                        ...(_currentQuiz!['options'] as List).asMap().entries.map(
                          (entry) {
                            final index = entry.key;
                            final option = entry.value;
                            final isSelected = _selectedAnswer == option;
                            final isCorrect =
                                option == _currentQuiz!['correct_answer'];
                            final showResult = _showExplanation;

                            // Türkçe karşılık
                            final optionsTurkish =
                                _currentQuiz!['options_turkish'] as List?;
                            final turkishTranslation =
                                optionsTurkish != null &&
                                    index < optionsTurkish.length
                                ? optionsTurkish[index] as String
                                : null;

                            Color? buttonColor;
                            Color? textColor;

                            if (showResult) {
                              if (isCorrect) {
                                buttonColor = Colors.green[700];
                                textColor = Colors.white;
                              } else if (isSelected) {
                                buttonColor = Colors.red[700];
                                textColor = Colors.white;
                              } else {
                                buttonColor =
                                    theme.colorScheme.surfaceContainer;
                                textColor = theme.colorScheme.onSurface;
                              }
                            } else if (isSelected) {
                              buttonColor = theme.colorScheme.primary;
                              textColor = Colors.white;
                            } else {
                              buttonColor = theme.colorScheme.surfaceContainer;
                              textColor = theme.colorScheme.onSurface;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: showResult
                                          ? null
                                          : () {
                                              setState(
                                                () => _selectedAnswer = option,
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                        backgroundColor: buttonColor,
                                        foregroundColor: textColor,
                                        elevation: isSelected && !showResult
                                            ? 4
                                            : 1,
                                      ),
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  if (turkishTranslation != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .surfaceContainer,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.translate,
                                                    size: 40,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    option,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme
                                                          .primaryContainer
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      turkishTranslation,
                                                      style: theme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Kapat'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.translate,
                                          size: 20,
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.7),
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: theme
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.3),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Explanation
                        if (_showExplanation)
                          Card(
                            color:
                                _selectedAnswer ==
                                    _currentQuiz!['correct_answer']
                                ? Colors.green[900]!.withValues(alpha: 0.3)
                                : Colors.red[900]!.withValues(alpha: 0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _selectedAnswer ==
                                                _currentQuiz!['correct_answer']
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color:
                                            _selectedAnswer ==
                                                _currentQuiz!['correct_answer']
                                            ? Colors.green[400]
                                            : Colors.red[400],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedAnswer ==
                                                _currentQuiz!['correct_answer']
                                            ? 'Richtig! (Doğru!)'
                                            : 'Falsch! (Yanlış!)',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _currentQuiz!['explanation'] ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Sabit buton - her zaman altta
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: _selectedAnswer == null
                          ? null
                          : _showExplanation
                          ? _nextQuestion
                          : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: Text(
                        _showExplanation
                            ? 'Nächste Frage (Sonraki Soru)'
                            : 'Antwort Senden (Gönder)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
