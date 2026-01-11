# Almanca AI - İyileştirme Önerileri

## 🔴 KRİTİK (Acil Çözülmeli)

### 1. SharedPreferences → SQLite Migrasyonu
**Risk:** 200+ kelime eklenince app crash (string limit ~1MB)
**Çözüm:** 
```dart
// sqflite package kullan
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3

// Veritabanı şeması:
CREATE TABLE vocabulary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  word TEXT NOT NULL,
  word_type TEXT,
  artikel TEXT,
  turkish TEXT NOT NULL,
  conjugation TEXT, -- JSON
  perfekt TEXT,
  example1 TEXT,
  example2 TEXT,
  added_date INTEGER,
  review_count INTEGER DEFAULT 0,
  last_reviewed INTEGER,
  difficulty INTEGER DEFAULT 0 -- Spaced repetition için
);

CREATE INDEX idx_word ON vocabulary(word);
CREATE INDEX idx_last_reviewed ON vocabulary(last_reviewed);
```

### 2. Rate Limiting (API Abuse Önleme)
**Risk:** Kullanıcı spam tuşlayarak Gemini API'yi limit aşımına uğratabilir
**Çözüm:**
```dart
// lib/core/utils/rate_limiter.dart
class RateLimiter {
  final Map<String, DateTime> _lastCalls = {};
  final Duration cooldown;
  
  RateLimiter({this.cooldown = const Duration(seconds: 2)});
  
  bool canMakeRequest(String key) {
    final last = _lastCalls[key];
    if (last == null) return true;
    return DateTime.now().difference(last) > cooldown;
  }
  
  void recordRequest(String key) {
    _lastCalls[key] = DateTime.now();
  }
}

// vocabulary_screen.dart içinde:
final _rateLimiter = RateLimiter(cooldown: Duration(seconds: 3));

Future<void> _addWord() async {
  if (!_rateLimiter.canMakeRequest('add_word')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Çok hızlı! 3 saniye bekleyin.')),
    );
    return;
  }
  _rateLimiter.recordRequest('add_word');
  // ... kelime ekleme
}
```

### 3. Error Handling İyileştirmesi
**Sorun:** Generic "Hata oluştu" mesajları kullanıcıya yardımcı olmuyor
**Çözüm:**
```dart
// lib/core/errors/app_errors.dart
enum ErrorType {
  network,
  apiLimit,
  invalidWord,
  timeout,
  serverError
}

class AppError {
  final ErrorType type;
  final String message;
  final String? userAction;
  
  AppError(this.type, this.message, {this.userAction});
  
  static AppError fromException(dynamic e) {
    if (e.toString().contains('quota')) {
      return AppError(
        ErrorType.apiLimit,
        'Günlük kelime ekleme limitine ulaştınız',
        userAction: 'Yarın tekrar deneyin veya manuel ekleyin',
      );
    }
    if (e.toString().contains('timeout')) {
      return AppError(
        ErrorType.timeout,
        'Bağlantı zaman aşımına uğradı',
        userAction: 'İnternet bağlantınızı kontrol edin',
      );
    }
    // ...
    return AppError(ErrorType.serverError, e.toString());
  }
}
```

## 🟡 ÖNEMLİ (Yakın Zamanda)

### 4. Offline Mode
**Sorun:** İnternet yoksa hiçbir şey çalışmaz
**Çözüm:**
```dart
// lib/core/network/connectivity_service.dart
class ConnectivityService {
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

// vocabulary_screen.dart
Future<void> _enrichAndAddWord(String word) async {
  final hasInternet = await ConnectivityService.hasInternet();
  
  if (!hasInternet) {
    // Offline mode: Doğrudan manuel dialog aç
    _showManualAddDialog(word);
    return;
  }
  
  // Online mode: Gemini API'ye git
  try {
    final enrichedData = await _aiService.enrichVocabulary(word);
    // ...
  } catch (e) {
    _showManualAddDialog(word); // Fallback
  }
}
```

### 5. Search & Filter (Arama/Filtreleme)
**Sorun:** 50+ kelime olunca kelime havuzunda gezinti zor
**Çözüm:**
```dart
// vocabulary_screen.dart
String _searchQuery = '';
String _filterType = 'all'; // all, verbs, nouns, adjectives

List<Map<String, dynamic>> get _filteredVocabulary {
  var filtered = _vocabulary;
  
  // Arama
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((word) {
      final german = word['word']?.toString().toLowerCase() ?? '';
      final turkish = word['turkish']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return german.contains(query) || turkish.contains(query);
    }).toList();
  }
  
  // Kelime tipi filtresi
  if (_filterType != 'all') {
    filtered = filtered.where((word) {
      return word['wordType'] == _filterType;
    }).toList();
  }
  
  return filtered;
}

// UI'da search bar ekle:
TextField(
  decoration: InputDecoration(
    hintText: 'Kelime ara (Almanca veya Türkçe)...',
    prefixIcon: Icon(Icons.search),
  ),
  onChanged: (value) {
    setState(() => _searchQuery = value);
  },
)
```

### 6. Spaced Repetition System (SRS)
**Sorun:** Kelimeler rastgele tekrarlanıyor, bilimsel hafıza güçlendirme yok
**Çözüm:**
```dart
// lib/core/models/vocabulary_item.dart
class VocabularyItem {
  final String word;
  final String turkish;
  DateTime lastReviewed;
  int reviewCount;
  double easeFactor; // 1.3 - 2.5
  int intervalDays; // 1, 3, 7, 14, 30...
  
  DateTime get nextReview => lastReviewed.add(Duration(days: intervalDays));
  
  bool get isDueForReview => DateTime.now().isAfter(nextReview);
  
  // SM-2 algoritması (SuperMemo)
  void updateAfterReview(int quality) { // 0-5 (0:fail, 5:perfect)
    reviewCount++;
    
    if (quality < 3) {
      // Başarısız - sıfırla
      intervalDays = 1;
    } else {
      // Başarılı - intervali artır
      if (reviewCount == 1) {
        intervalDays = 1;
      } else if (reviewCount == 2) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
    }
    
    // Ease factor güncelle
    easeFactor = max(1.3, easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)));
    lastReviewed = DateTime.now();
  }
}

// Quiz'de kullan:
void _generateQuestion() {
  // Önce review edilmesi gereken kelimeleri getir
  final dueWords = _vocabulary.where((w) => w.isDueForReview).toList();
  final wordsToReview = dueWords.isEmpty ? _vocabulary : dueWords;
  // ...
}
```

### 7. Progress Dashboard
**Sorun:** Kullanıcı ilerlemesini göremiyor, motivasyon düşük
**Çözüm:**
```dart
// lib/features/progress/models/user_stats.dart
class UserStats {
  final int totalWords;
  final int masteredWords; // 5+ kez doğru cevaplanan
  final int learningWords; // 1-4 kez görülen
  final int newWords; // Hiç quiz'de görülmeyen
  final int currentStreak; // Ardışık gün sayısı
  final int longestStreak;
  final DateTime? lastStudyDate;
  final Map<String, int> weeklyActivity; // Haftanın günleri
  
  double get masteryPercentage => totalWords > 0 
    ? (masteredWords / totalWords * 100) 
    : 0;
}

// UI: Charts kullan (fl_chart package)
dependencies:
  fl_chart: ^0.65.0

LineChart(
  // Son 7 günün activity'si
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: weeklyData.map((day, count) => 
          FlSpot(day, count.toDouble())
        ).toList(),
      ),
    ],
  ),
)
```

## 🟢 İYİLEŞTİRME (Nice-to-Have)

### 8. Audio Pronunciation (Sesli Telaffuz)
**Fayda:** Kullanıcı doğru telaffuzu öğrenir
**Çözüm:**
```dart
dependencies:
  flutter_tts: ^3.8.5

class PronunciationService {
  final FlutterTts _tts = FlutterTts();
  
  Future<void> init() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.5); // Yavaş konuş
  }
  
  Future<void> speak(String word) async {
    await _tts.speak(word);
  }
}

// vocabulary_screen.dart'ta:
IconButton(
  icon: Icon(Icons.volume_up),
  onPressed: () => _pronunciationService.speak(word['word']),
)
```

### 9. Cloud Sync (Bulut Senkronizasyonu)
**Fayda:** Telefon değiştiğinde veri kaybı yok
**Çözüm:**
```dart
// Supabase database kullan (zaten var)
// vocabulary tablosu oluştur:

CREATE TABLE user_vocabulary (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  word TEXT NOT NULL,
  turkish TEXT NOT NULL,
  word_type TEXT,
  conjugation JSONB,
  perfekt TEXT,
  added_at TIMESTAMP DEFAULT NOW(),
  last_reviewed_at TIMESTAMP,
  review_count INTEGER DEFAULT 0
);

CREATE INDEX idx_user_vocab ON user_vocabulary(user_id);

-- RLS policies:
ALTER TABLE user_vocabulary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own vocabulary"
  ON user_vocabulary FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own vocabulary"
  ON user_vocabulary FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### 10. Batch Processing (Toplu İşlem)
**Sorun:** Her kelime için ayrı API call, yavaş ve inefficient
**Çözüm:**
```typescript
// supabase/functions/vocabulary-enricher-batch/index.ts
serve(async (req) => {
  const { words } = await req.json(); // String array
  
  const prompt = `Analyze these German words and return JSON array:
  ${words.join(', ')}
  
  Return array format:
  [
    {wordType: "verb", word: "trinken", turkish: "içmek", ...},
    {wordType: "noun", word: "Haus", turkish: "ev", ...}
  ]`;
  
  // Tek Gemini call ile tüm kelimeleri işle
  const response = await fetch(geminiUrl, { ... });
  // ...
});
```

### 11. Example Sentences from Real Content
**Sorun:** Example sentences generic ve yapay
**Çözüm:**
```dart
// Tatoeba API kullan (gerçek cümleler)
// https://tatoeba.org/en/api_v0/search

Future<List<String>> _getRealExamples(String word) async {
  final url = 'https://tatoeba.org/en/api_v0/search?query=$word&from=deu&to=tur';
  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);
  
  return data['results']
    .take(2)
    .map((r) => r['text'] as String)
    .toList();
}
```

### 12. Gamification
**Fayda:** Kullanıcı bağlılığı artırır
**Özellikler:**
- 🏆 Achievements (100 kelime, 7 günlük streak, etc.)
- ⭐ Daily goals (Günde 5 yeni kelime)
- 🎯 Leaderboard (arkadaşlarla yarış - isteğe bağlı)
- 🔥 Streak tracking (ardışık gün takibi)

### 13. Image Support
**Fayda:** Görsel hafıza güçlendirir
**Çözüm:**
```dart
// Unsplash API ile kelimeye uygun resim getir
dependencies:
  cached_network_image: ^3.3.1

Future<String?> _getWordImage(String word) async {
  final apiKey = 'YOUR_UNSPLASH_ACCESS_KEY';
  final url = 'https://api.unsplash.com/search/photos?query=$word&per_page=1';
  
  final response = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Client-ID $apiKey'},
  );
  
  final data = jsonDecode(response.body);
  return data['results'][0]['urls']['small'];
}

// UI'da:
CachedNetworkImage(
  imageUrl: word['imageUrl'] ?? 'placeholder.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
)
```

## 📊 Performans İyileştirmeleri

### 14. Lazy Loading
**Sorun:** 500 kelime yüklendiğinde ListView yavaşlıyor
**Çözüm:**
```dart
// Pagination ekle
ListView.builder(
  itemCount: min(_currentPage * 20, _vocabulary.length),
  controller: _scrollController,
  itemBuilder: (context, index) {
    if (index == (_currentPage * 20) - 1) {
      _loadMoreWords(); // Next page
    }
    return VocabularyCard(word: _vocabulary[index]);
  },
)
```

### 15. Caching
**Sorun:** Aynı kelime tekrar istendiğinde yeniden API call
**Çözüm:**
```dart
// lib/core/cache/vocabulary_cache.dart
class VocabularyCache {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const maxAge = Duration(hours: 24);
  
  static void set(String word, Map<String, dynamic> data) {
    _cache[word] = {
      ...data,
      '_cachedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  static Map<String, dynamic>? get(String word) {
    final cached = _cache[word];
    if (cached == null) return null;
    
    final age = DateTime.now().millisecondsSinceEpoch - cached['_cachedAt'];
    if (age > maxAge.inMilliseconds) {
      _cache.remove(word);
      return null;
    }
    return cached;
  }
}

// Kullanım:
Future<Map<String, dynamic>> enrichVocabulary(String word) async {
  final cached = VocabularyCache.get(word);
  if (cached != null) return cached;
  
  final result = await _apiCall(word);
  VocabularyCache.set(word, result);
  return result;
}
```

## 🔒 Güvenlik İyileştirmeleri

### 16. Anon Key Rate Limiting
**Risk:** Supabase anon key exposed, abuse edilebilir
**Çözüm:**
```typescript
// Supabase dashboard → API Settings → Rate Limiting
// Edge Function'da IP-based rate limit:

const rateLimitMap = new Map<string, number[]>();

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const requests = rateLimitMap.get(ip) || [];
  
  // Son 1 dakikadaki requestleri filtrele
  const recentRequests = requests.filter(time => now - time < 60000);
  
  if (recentRequests.length >= 10) { // Max 10 req/min
    return false;
  }
  
  recentRequests.push(now);
  rateLimitMap.set(ip, recentRequests);
  return true;
}

// Function başında:
const clientIp = req.headers.get('x-forwarded-for') || 'unknown';
if (!checkRateLimit(clientIp)) {
  return new Response(
    JSON.stringify({ error: 'Rate limit exceeded' }),
    { status: 429 }
  );
}
```

### 17. Input Validation
**Risk:** Malicious input (SQL injection, XSS gibi)
**Çözüm:**
```dart
// lib/core/validators/input_validator.dart
class InputValidator {
  static bool isValidGermanWord(String word) {
    // Sadece German karakterler
    final regex = RegExp(r'^[a-zA-ZäöüßÄÖÜ\s-]+$');
    return regex.hasMatch(word) && word.length <= 50;
  }
  
  static String sanitize(String input) {
    return input
      .replaceAll(RegExp(r'[<>]'), '') // XSS prevention
      .replaceAll(RegExp(r'[;\'"]'), '') // SQL injection prevention
      .trim();
  }
}

// Kullanım:
Future<void> _addWord() async {
  final word = InputValidator.sanitize(_wordController.text);
  
  if (!InputValidator.isValidGermanWord(word)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçersiz kelime formatı!')),
    );
    return;
  }
  // ...
}
```

## 🎨 UI/UX İyileştirmeleri

### 18. Empty States
**Sorun:** Boş ekranlarda kullanıcı ne yapacağını bilmiyor
**Çözüm:**
```dart
// Empty state widget
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
      SizedBox(height: 16),
      Text(
        'Henüz kelime eklemediniz',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        'Almanca bir kelime yazıp + butonuna basarak başlayın',
        style: TextStyle(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 24),
      ElevatedButton.icon(
        icon: Icon(Icons.add),
        label: Text('İlk Kelimeyi Ekle'),
        onPressed: () {
          _wordController.text = 'Hallo'; // Örnek kelime
        },
      ),
    ],
  ),
)
```

### 19. Loading States
**Sorun:** Kullanıcı API call sırasında ne olduğunu bilmiyor
**Çözüm:**
```dart
// Skeleton loading
dependencies:
  shimmer: ^3.0.0

Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Column(
    children: List.generate(3, (i) => 
      Container(
        height: 80,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      )
    ),
  ),
)
```

### 20. Onboarding Flow
**Fayda:** İlk kullanıcılar için rehber
**Çözüm:**
```dart
dependencies:
  introduction_screen: ^3.1.12

IntroductionScreen(
  pages: [
    PageViewModel(
      title: "Almanca kelime öğrenin",
      body: "AI destekli kelime zenginleştirme ile...",
      image: Center(child: Icon(Icons.book, size: 100)),
    ),
    // ... daha fazla page
  ],
  onDone: () => _completeOnboarding(),
  showSkipButton: true,
)
```

## 📈 Analytics (İsteğe Bağlı)

### 21. Kullanıcı Davranışı Takibi
**Fayda:** Hangi özellikler kullanılıyor, nerede hata oluyor?
**Çözüm:**
```dart
dependencies:
  firebase_analytics: ^10.8.0

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  void logWordAdded(String word, String source) { // 'api' or 'manual'
    _analytics.logEvent(
      name: 'word_added',
      parameters: {'word_length': word.length, 'source': source},
    );
  }
  
  void logQuizCompleted(int score, int total) {
    _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {'score': score, 'total': total},
    );
  }
}
```

## 🚀 ÖNCELİKLENDİRME

**Hemen Yap (1 hafta):**
1. ✅ Rate Limiting (API abuse önleme)
2. ✅ Error Handling iyileştirme
3. ✅ Search & Filter
4. ✅ Empty States

**Kısa Vadede (2-4 hafta):**
5. ✅ SQLite migration (SharedPreferences yerine)
6. ✅ Offline mode
7. ✅ Progress dashboard
8. ✅ Spaced Repetition (SRS)

**Uzun Vadede (1-3 ay):**
9. ✅ Cloud sync (Supabase database)
10. ✅ Audio pronunciation
11. ✅ Gamification
12. ✅ Analytics

**İsteğe Bağlı:**
- Image support
- Batch processing
- Real example sentences
- Advanced caching
