import 'dart:io';

/// İnternet bağlantı kontrolü
class ConnectivityService {
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canReachSupabase() async {
    try {
      final result = await InternetAddress.lookup(
        'gohrxehnreohljgsxlig.supabase.co',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
