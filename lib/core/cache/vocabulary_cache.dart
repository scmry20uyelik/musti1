/// Kelime önbellek sistemi
class VocabularyCache {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const Duration maxAge = Duration(hours: 24);

  /// Kelimeyi cache'e ekle
  static void set(String word, Map<String, dynamic> data) {
    _cache[word.toLowerCase()] = {
      ...data,
      '_cachedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Cache'ten kelime al
  static Map<String, dynamic>? get(String word) {
    final cached = _cache[word.toLowerCase()];
    if (cached == null) return null;

    final cachedAt = cached['_cachedAt'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;

    // 24 saatten eski ise sil
    if (age > maxAge.inMilliseconds) {
      _cache.remove(word.toLowerCase());
      return null;
    }

    // _cachedAt alanını kaldır
    final result = Map<String, dynamic>.from(cached);
    result.remove('_cachedAt');
    return result;
  }

  /// Cache'i temizle
  static void clear() {
    _cache.clear();
  }

  /// Cache boyutu
  static int get size => _cache.length;

  /// Eski entryleri temizle
  static void cleanOld() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _cache.removeWhere((key, value) {
      final cachedAt = value['_cachedAt'] as int;
      return (now - cachedAt) > maxAge.inMilliseconds;
    });
  }
}
