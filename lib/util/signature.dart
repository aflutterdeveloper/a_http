import 'dart:convert';

import 'package:crypto/crypto.dart' as Crypto;
import 'dart:convert' show utf8;

class Signature {
  static String _secretKey = '3so475lyybookuvj1tc6gmxrki9pwf2d';

  static String generateMd5(String data) {
    var content = utf8.encode(data);
    var digest = Crypto.md5.convert(content);
    return digest.toString();
  }

  static Future<String> getSha1(
      Map<dynamic, dynamic> params, dynamic body, int timestamp) async {
    String destUrl = '';
    String paramsUrl = map2url(params);
    print('params ------$paramsUrl');
    String bodyUrl = map2url(body);
    print('bodyUrl ------$bodyUrl');
    if (paramsUrl?.isNotEmpty == true) {
      destUrl += '$paramsUrl';
    }
    destUrl += ";";
    if (bodyUrl?.isNotEmpty == true) {
      destUrl += '$bodyUrl';
    }
    destUrl += ";";
    destUrl += '$timestamp;';
    destUrl += '$_secretKey';
    print('destURl; $destUrl');

    // Crypto.Digest res = sha1(SofaNovelConfig.secretKey, destUrl);
    // var result = base64Encode(res.bytes);

    var key = utf8.encode(_secretKey);
    var bytes = utf8.encode(destUrl);

    var hmacSha1 = new Crypto.Hmac(Crypto.sha1, key); // HMAC-SHA1
    Crypto.Digest res = hmacSha1.convert(bytes);
    var result = base64Encode(res.bytes);
    print('sha1, $result');
    return result;
  }

  static String map2url(dynamic body) {
    if (body == null || body is String) {
      return body;
    }
    var str = '';
    body.forEach((item, value) {
      if (str != '') {
        str += '&';
      }
      str += '$item=$value';
    });
    return str;
  }
}
