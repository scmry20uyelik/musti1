/// Rate Limiter - API abuse önleme
class RateLimiter {
  final Map<String, DateTime> _lastCalls = {};
  final Duration cooldown;

  RateLimiter({this.cooldown = const Duration(seconds: 3)});

  bool canMakeRequest(String key) {
    final last = _lastCalls[key];
    if (last == null) return true;
    return DateTime.now().difference(last) > cooldown;
  }

  void recordRequest(String key) {
    _lastCalls[key] = DateTime.now();
  }

  int? getRemainingSeconds(String key) {
    final last = _lastCalls[key];
    if (last == null) return null;
    final elapsed = DateTime.now().difference(last);
    if (elapsed > cooldown) return null;
    return cooldown.inSeconds - elapsed.inSeconds;
  }
}
