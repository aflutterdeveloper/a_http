import 'dart:convert';

import 'package:autility/utility/a_log.dart';
import 'package:dio/dio.dart';

class AHttpTransformer extends DefaultTransformer {
  AHttpTransformer() : super(jsonDecodeCallback: jsonDecoder);

  static dynamic jsonDecoder(String input) {
    final t = DateTime.now().millisecondsSinceEpoch;
    final result = json.decode(input);
    ALog.info("AHttpTransformer",
        "decode durarion:${DateTime.now().millisecondsSinceEpoch - t}");
    return result;
  }
}
