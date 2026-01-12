import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class VocabularyQuizScreen extends StatefulWidget {
  const VocabularyQuizScreen({super.key});

  @override
  State<VocabularyQuizScreen> createState() => _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends State<VocabularyQuizScreen> {
  List<Map<String, dynamic>> _vocabulary = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  bool _quizStarted = false;
  bool _showAnswer = false;
  String _userAnswer = '';
  final TextEditingController _answerController = TextEditingController();

  // Quiz soru tipi
  String _questionType = '';
  String _question = '';
  String _correctAnswer = '';
  Map<String, dynamic>? _currentWord;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabJson = prefs.getString('vocabulary_list');
    if (vocabJson != null) {
      setState(() {
        // Turkish field'ı olan kelimeleri filtrele
        _vocabulary = List<Map<String, dynamic>>.from(jsonDecode(vocabJson))
            .where((word) {
              final turkish = word['turkish'];
              if (turkish == null) return false;
              if (turkish.toString().trim().isEmpty) return false;
              if (turkish.toString().toLowerCase() == 'null') return false;
              if (turkish.toString() == '(Türkçe yok)') return false;
              return true;
            })
            .toList();
        if (_vocabulary.isNotEmpty) {
          _vocabulary.shuffle(Random());
          _totalQuestions = min(10, _vocabulary.length);
        }
      });
    }
  }

  void _startQuiz() {
    if (_vocabulary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kelime havuzunda kelime yok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _quizStarted = true;
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    if (_currentQuestionIndex >= _totalQuestions) {
      // Quiz bitti
      return;
    }

    _currentWord = _vocabulary[_currentQuestionIndex];
    final random = Random();
    final questionTypes = <String>[];

    // Her kelime için mevcut soru tiplerini belirle
    questionTypes.add('german_to_turkish'); // Almanca → Türkçe
    questionTypes.add('turkish_to_german'); // Türkçe → Almanca

    if (_currentWord!['wordType'] == 'verb' &&
        _currentWord!['conjugation'] != null) {
      questionTypes.add('conjugation_ich');
      questionTypes.add('conjugation_du');
      questionTypes.add('conjugation_er');
      if (_currentWord!['perfekt'] != null) {
        questionTypes.add('perfekt');
      }
    }

    _questionType = questionTypes[random.nextInt(questionTypes.length)];

    setState(() {
      _showAnswer = false;
      _userAnswer = '';
      _answerController.clear();

      switch (_questionType) {
        case 'german_to_turkish':
          _question =
              'Bu kelimenin Türkçe karşılığı nedir?\n\n${_currentWord!['artikel'] != '-' ? '${_currentWord!['artikel']} ' : ''}${_currentWord!['word']}';
          _correctAnswer = _currentWord!['turkish'] ?? '';
          break;

        case 'turkish_to_german':
          _question =
              'Bu Türkçe kelimenin Almanca karşılığı nedir?\n\n${_currentWord!['turkish']}';
          _correctAnswer = _currentWord!['word'] ?? '';
          break;

        case 'conjugation_ich':
          _question =
              '"${_currentWord!['word']}" fiilinin "ich" çekimi nedir?\n\nich ...?';
          _correctAnswer = _currentWord!['conjugation']['ich'] ?? '';
          break;

        case 'conjugation_du':
          _question =
              '"${_currentWord!['word']}" fiilinin "du" çekimi nedir?\n\ndu ...?';
          _correctAnswer = _currentWord!['conjugation']['du'] ?? '';
          break;

        case 'conjugation_er':
          _question =
              '"${_currentWord!['word']}" fiilinin "er/sie/es" çekimi nedir?\n\ner/sie/es ...?';
          _correctAnswer = _currentWord!['conjugation']['er_sie_es'] ?? '';
          break;

        case 'perfekt':
          _question =
              '"${_currentWord!['word']}" fiilinin Perfekt formu nedir?\n\n(haben/sein + Partizip II)';
          _correctAnswer = _currentWord!['perfekt'] ?? '';
          break;
      }
    });
  }

  String _normalizeText(String text) {
    // Almanca ve Türkçe karakterleri normalize et
    return text
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ä', 'a')
        .replaceAll('ß', 'ss')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .trim();
  }

  void _checkAnswer() {
    final userAnswerNormalized = _normalizeText(_answerController.text);
    final correctAnswerNormalized = _normalizeText(_correctAnswer);

    setState(() {
      _showAnswer = true;
      _userAnswer = _answerController.text.trim();

      if (userAnswerNormalized == correctAnswerNormalized) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      if (_currentQuestionIndex < _totalQuestions) {
        _generateQuestion();
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      _quizStarted = false;
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _vocabulary.shuffle(Random());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_quizStarted) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Kelime Quiz',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.quiz, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text(
                  'Kelime Quiz',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kelime havuzunuzdaki ${_vocabulary.length} kelime ile quiz yapın!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Türkçe ↔ Almanca çeviriler\n• Fiil çekimleri\n• Perfekt formları',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _vocabulary.isEmpty ? null : _startQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Quiz Başlat',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Quiz bitti mi?
    if (_currentQuestionIndex >= _totalQuestions) {
      final percentage = (_correctAnswers / _totalQuestions * 100).round();
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Quiz Sonucu',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: percentage >= 70
                          ? [Colors.green, Colors.green.shade700]
                          : percentage >= 50
                          ? [Colors.orange, Colors.orange.shade700]
                          : [Colors.red, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (percentage >= 70
                                    ? Colors.green
                                    : percentage >= 50
                                    ? Colors.orange
                                    : Colors.red)
                                .withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    percentage >= 70
                        ? Icons.emoji_events
                        : percentage >= 50
                        ? Icons.thumb_up
                        : Icons.refresh,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Quiz Tamamlandı!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_correctAnswers / $_totalQuestions',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Doğru Cevap',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _correctAnswers / _totalQuestions,
                          minHeight: 12,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage >= 70
                                ? Colors.green
                                : percentage >= 50
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '%$percentage Başarı',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: percentage >= 70
                              ? Colors.green
                              : percentage >= 50
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary,
                            theme.colorScheme.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _restartQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          'Tekrar Dene',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(Icons.home, color: theme.colorScheme.primary),
                      label: Text(
                        'Ana Sayfa',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Quiz sorusu göster
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Soru ${_currentQuestionIndex + 1}/$_totalQuestions',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _totalQuestions,
                minHeight: 8,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Soru kartı
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _question,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cevap input
            if (!_showAnswer) ...[
              TextField(
                controller: _answerController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Cevabınızı yazın...',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Cevabı Kontrol Et',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            // Cevap sonucu
            if (_showAnswer) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      _normalizeText(_userAnswer) ==
                          _normalizeText(_correctAnswer)
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _normalizeText(_userAnswer) ==
                            _normalizeText(_correctAnswer)
                        ? Colors.green
                        : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _normalizeText(_userAnswer) ==
                              _normalizeText(_correctAnswer)
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 64,
                      color:
                          _normalizeText(_userAnswer) ==
                              _normalizeText(_correctAnswer)
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _normalizeText(_userAnswer) ==
                              _normalizeText(_correctAnswer)
                          ? 'Doğru!'
                          : 'Yanlış!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            _normalizeText(_userAnswer) ==
                                _normalizeText(_correctAnswer)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (_normalizeText(_userAnswer) !=
                        _normalizeText(_correctAnswer)) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Senin cevabın:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        _userAnswer,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Doğru cevap:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    Text(
                      _correctAnswer,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    'Sonraki Soru',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Skor gösterimi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Skor: $_correctAnswers / ${_currentQuestionIndex + (_showAnswer ? 1 : 0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}
