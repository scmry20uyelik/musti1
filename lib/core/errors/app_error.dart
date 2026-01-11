/// Uygulama hata tipleri
enum ErrorType { network, apiLimit, invalidWord, timeout, serverError, unknown }

/// Gelişmiş hata sınıfı
class AppError {
  final ErrorType type;
  final String message;
  final String? userAction;

  AppError(this.type, this.message, {this.userAction});

  static AppError fromException(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('quota') || errorString.contains('limit')) {
      return AppError(
        ErrorType.apiLimit,
        'Günlük kelime ekleme limitine ulaştınız',
        userAction: 'Yarın tekrar deneyin veya manuel ekleyin',
      );
    }

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return AppError(
        ErrorType.timeout,
        'Bağlantı zaman aşımına uğradı',
        userAction: 'İnternet bağlantınızı kontrol edin',
      );
    }

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return AppError(
        ErrorType.network,
        'İnternet bağlantısı yok',
        userAction: 'Wi-Fi veya mobil veriyi kontrol edin',
      );
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return AppError(
        ErrorType.invalidWord,
        'Kelime bulunamadı',
        userAction: 'Farklı bir kelime deneyin',
      );
    }

    if (errorString.contains('500') || errorString.contains('server error')) {
      return AppError(
        ErrorType.serverError,
        'Sunucu hatası',
        userAction: 'Lütfen daha sonra tekrar deneyin',
      );
    }

    return AppError(
      ErrorType.unknown,
      'Beklenmeyen bir hata oluştu',
      userAction: 'Manuel olarak eklemeyi deneyin',
    );
  }
}
