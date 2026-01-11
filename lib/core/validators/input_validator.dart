/// Input Validator - Güvenlik ve veri doğrulama
class InputValidator {
  /// Almanca kelime formatını kontrol eder
  static bool isValidGermanWord(String word) {
    // Sadece Almanca karakterler: a-z, ä, ö, ü, ß
    final regex = RegExp(r'^[a-zA-ZäöüßÄÖÜ\s-]+$');
    return regex.hasMatch(word) && word.length > 0 && word.length <= 50;
  }

  /// Input'u temizler (XSS, SQL injection önleme)
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[<>]'), '') // XSS prevention
        .replaceAll(';', '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim();
  }

  /// Türkçe karakterlerin olup olmadığını kontrol eder
  static bool hasTurkishChars(String text) {
    return RegExp(r'[çğıöşüÇĞİÖŞÜ]').hasMatch(text);
  }

  /// Boşluk karakterlerini normalize eder
  static String normalizeSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
