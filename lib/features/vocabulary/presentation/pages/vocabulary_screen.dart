import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import '../../../../core/network/ai_api_service.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/cache/vocabulary_cache.dart';
import '../../../../core/utils/rate_limiter.dart';
import '../../../../core/validators/input_validator.dart';
import '../../../../core/errors/app_error.dart';
import 'vocabulary_quiz_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _vocabulary = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  List<String> _suggestions = [];
  String _originalWord = '';
  String _searchQuery = '';
  String _filterType = 'all'; // all, verb, noun, adjective
  final _aiService = AiApiService.instance;
  final _rateLimiter = RateLimiter(cooldown: const Duration(seconds: 3));

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
        _vocabulary = List<Map<String, dynamic>>.from(jsonDecode(vocabJson));
      });
    }
  }

  Future<void> _saveVocabulary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vocabulary_list', jsonEncode(_vocabulary));
  }

  List<Map<String, dynamic>> get _filteredVocabulary {
    var filtered = _vocabulary;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((word) {
        final german = word['word']?.toString().toLowerCase() ?? '';
        final turkish = word['turkish']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return german.contains(query) || turkish.contains(query);
      }).toList();
    }

    // Tip filtresi
    if (_filterType != 'all') {
      filtered = filtered.where((word) {
        return word['wordType'] == _filterType;
      }).toList();
    }

    return filtered;
  }

  Future<void> _addWord() async {
    final rawWord = _wordController.text.trim();
    if (rawWord.isEmpty) return;

    // Input validation
    final word = InputValidator.sanitize(rawWord);

    if (!InputValidator.isValidGermanWord(word)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçersiz kelime! Sadece Almanca harfler kullanın.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (InputValidator.hasTurkishChars(word)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Almanca kelime girmelisiniz, Türkçe değil!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Rate limiting kontrolü
    if (!_rateLimiter.canMakeRequest('add_word')) {
      final remaining = _rateLimiter.getRemainingSeconds('add_word');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çok hızlı! $remaining saniye bekleyin.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _rateLimiter.recordRequest('add_word');
    await _enrichAndAddWord(word);
  }

  Future<void> _enrichAndAddWord(String word) async {
    setState(() => _isLoading = true);

    try {
      // Önce internet kontrolü
      final hasInternet = await ConnectivityService.hasInternet();

      if (!hasInternet) {
        setState(() => _isLoading = false);

        if (mounted) {
          // Offline mode: Doğrudan manuel dialog aç
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Çevrimdışı Mod'),
                ],
              ),
              content: const Text(
                'İnternet bağlantısı yok. Kelimeyi manuel olarak ekleyebilirsiniz.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showManualAddDialog(word);
                  },
                  child: const Text('Manuel Ekle'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Gemini API üzerinden kelime zenginleştirme
      Map<String, dynamic>? enrichedData;

      // Önce cache'e bak
      final cached = VocabularyCache.get(word);
      if (cached != null) {
        enrichedData = cached;
        debugPrint('✅ Cache\'ten alındı: ${enrichedData['turkish']}');
      } else {
        // Cache'te yok, API'ye git
        try {
          enrichedData = await _aiService.enrichVocabulary(word);
          debugPrint(
            '✅ Edge Function (Gemini)\'den alındı: ${enrichedData['turkish']}',
          );

          // Cache'e kaydet
          VocabularyCache.set(word, enrichedData);
        } catch (apiError) {
          debugPrint('⚠️ Edge Function başarısız: $apiError');

          // Hata tipini belirle
          final appError = AppError.fromException(apiError);

          setState(() => _isLoading = false);

          if (mounted) {
            // Detaylı hata mesajı göster
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400]),
                    const SizedBox(width: 8),
                    const Text('Hata'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appError.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (appError.userAction != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Öneri: ${appError.userAction}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Kapat'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showManualAddDialog(word);
                    },
                    child: const Text('Manuel Ekle'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      // enrichedData null check
      if (enrichedData == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Kelime zaten var mı kontrol et
      final enrichedWord = (enrichedData['word'] as String).toLowerCase();
      final existingIndex = _vocabulary.indexWhere(
        (item) => (item['word'] as String).toLowerCase() == enrichedWord,
      );

      if (existingIndex != -1) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${enrichedData['word']}" zaten listede mevcut!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _wordController.clear();
        return;
      }

      setState(() {
        _vocabulary.insert(0, {
          'word': enrichedData!['word'],
          'artikel': enrichedData['artikel'] ?? '-',
          'wordType': enrichedData['wordType'] ?? 'unknown',
          'turkish': enrichedData['turkish'] ?? '(Türkçe yok)',
          'conjugation': enrichedData['conjugation'],
          'perfekt': enrichedData['perfekt'] ?? '-',
          'example1': enrichedData['example1'] ?? '',
          'example2': enrichedData['example2'] ?? '',
          'addedAt': DateTime.now().toIso8601String(),
        });
        _wordController.clear();
        _showSuggestions = false;
        _suggestions = [];
        _originalWord = '';
        _isLoading = false;
      });

      await _saveVocabulary();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kelime eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWord(int index) async {
    setState(() {
      _vocabulary.removeAt(index);
    });
    await _saveVocabulary();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kelime silindi'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Havuzum'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VocabularyQuizScreen(),
                ),
              );
            },
            icon: const Icon(Icons.quiz),
            tooltip: 'Quiz Yap',
          ),
        ],
      ),
      body: Column(
        children: [
          // Kelime ekleme alanı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Yeni Kelime Ekle',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _wordController,
                        decoration: InputDecoration(
                          hintText: 'Almanca kelime girin...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          prefixIcon: const Icon(Icons.translate),
                        ),
                        onSubmitted: (_) => _addWord(),
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _addWord,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'AI otomatik olarak artikel ve örnek cümleler ekleyecek',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Arama ve filtre
          if (_vocabulary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Kelime ara (Almanca veya Türkçe)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Filtre:', style: theme.textTheme.labelLarge),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('Tümü'),
                                selected: _filterType == 'all',
                                onSelected: (_) {
                                  setState(() => _filterType = 'all');
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Fiiller'),
                                selected: _filterType == 'verb',
                                onSelected: (_) {
                                  setState(() => _filterType = 'verb');
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('İsimler'),
                                selected: _filterType == 'noun',
                                onSelected: (_) {
                                  setState(() => _filterType = 'noun');
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Sıfatlar'),
                                selected: _filterType == 'adjective',
                                onSelected: (_) {
                                  setState(() => _filterType = 'adjective');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Öneri çekmecesi - Google gibi
          if (_showSuggestions)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '"$_originalWord" doğru yazılmamış olabilir',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          onPressed: () {
                            setState(() {
                              _showSuggestions = false;
                              _suggestions = [];
                              _originalWord = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  ..._suggestions.map(
                    (suggestion) => InkWell(
                      onTap: () => _enrichAndAddWord(suggestion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(suggestion, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _enrichAndAddWord(_originalWord),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 20,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Yine de "$_originalWord" kullan',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Kelime listesi
          Expanded(
            child: _isLoading && _vocabulary.isEmpty
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : _vocabulary.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 100,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Henüz kelime eklemediniz',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Almanca bir kelime yazıp + butonuna basarak başlayın',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('İlk Kelimeyi Ekle'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () {
                            _wordController.text = 'Hallo';
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                        ),
                      ],
                    ),
                  )
                : _filteredVocabulary.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kelime bulunamadı',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Farklı bir arama yapın',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredVocabulary.length,
                    itemBuilder: (context, index) {
                      final item = _filteredVocabulary[index];
                      final originalIndex = _vocabulary.indexOf(item);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              item['artikel'] ?? '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                '${item['artikel'] != '-' ? '${item['artikel']} ' : ''}${item['word'] ?? ''}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item['turkish'] != null &&
                                  item['turkish'].toString().isNotEmpty)
                                Text(
                                  '🇹🇷 ${item['turkish']}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red[400],
                            onPressed: () => _deleteWord(originalIndex),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Verb conjugation table (if verb)
                                  if (item['wordType'] == 'verb' &&
                                      item['conjugation'] != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Çekimler:',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildConjugationRow(
                                            'ich',
                                            item['conjugation']['ich'] ?? '',
                                            'wir',
                                            item['conjugation']['wir'] ?? '',
                                            theme,
                                          ),
                                          _buildConjugationRow(
                                            'du',
                                            item['conjugation']['du'] ?? '',
                                            'ihr',
                                            item['conjugation']['ihr'] ?? '',
                                            theme,
                                          ),
                                          _buildConjugationRow(
                                            'er/sie/es',
                                            item['conjugation']['er_sie_es'] ??
                                                '',
                                            'sie/Sie',
                                            item['conjugation']['sie_Sie'] ??
                                                '',
                                            theme,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Perfekt form
                                    if (item['perfekt'] != null &&
                                        item['perfekt'].toString().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 20,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Perfekt: ',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                            ),
                                            Expanded(
                                              child: SelectableText(
                                                item['perfekt'] ?? '',
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                  ],
                                  // Example sentences
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.looks_one,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SelectableText(
                                          item['example1'] ?? '',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.looks_two,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SelectableText(
                                          item['example2'] ?? '',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Eklenme: ${_formatDate(item['addedAt'] ?? '')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildConjugationRow(
    String pronoun1,
    String verb1,
    String pronoun2,
    String verb2,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$pronoun1: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: verb1),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$pronoun2: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: verb2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog(String word) {
    final turkishController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manuel Kelime Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$word kelimesi sözlükte yok.'),
            const SizedBox(height: 16),
            TextField(
              controller: turkishController,
              decoration: const InputDecoration(
                labelText: 'Türkçe Anlamı',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final turkish = turkishController.text.trim();
              if (turkish.isNotEmpty) {
                setState(() {
                  _vocabulary.add({
                    'word': word,
                    'artikel': '-',
                    'turkish': turkish,
                    'example1': '',
                    'example2': '',
                  });
                  _saveVocabulary();
                  _wordController.clear();
                  _isLoading = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$word eklendi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }
}
