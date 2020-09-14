import 'dart:convert';

import 'package:crypto/crypto.dart' as Crypto;
import 'dart:convert' show utf8;

class ServerTimeUtil {
  static int _serverTimeBase;
  static int _localTimeBase;

  static void initServerTime(int time) {
    if (_serverTimeBase == null) {
      updateServerTime(time);
    }
  }

  static void updateServerTime(int time) {
    if (time != null && time > 0) {
      _serverTimeBase = time;
      _localTimeBase = _now();
    }
  }

  static int get time {
    return _serverTimeBase + _now() - _localTimeBase;
  }

  static int _now() {
    return (DateTime.now().millisecondsSinceEpoch / 1000).floor();
  }
}
