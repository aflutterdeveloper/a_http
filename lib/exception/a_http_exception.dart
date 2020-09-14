
import 'package:a_thread_pool/a_thread_pool.dart';

enum AHttpCode {
  SUCCEED,
  FAILED,
  PARAM_ERROR,
  AUTH_FAIL,
  EXPIRED,
  NOT_FOUND,
  UNKNOWN_DATA,
  JSON_PARSE_ERROR,
  NETWORK_FAIL,
  ERROR_10002,
  SEND_TIMEOUT,
  RECEIVE_TIMEOUT,
  CONNECT_TIMEOUT,
}

class AHttpException extends AException {
  AHttpException(this.code, {String error}) : super(error);

  final AHttpCode code;
  @override
  String toString() {
    return "err:$code, msg:$error";
  }
}

AHttpCode statusCode2HttpCode(int status) {
  if (status == null) {
    return AHttpCode.FAILED;
  }

  if (status >= 200 && status < 300) {
    return AHttpCode.SUCCEED;
  } else if (status == 401) {
    return AHttpCode.AUTH_FAIL;
  } else if (status == 403) {
    return AHttpCode.EXPIRED;
  } else if (status == 404) {
    return AHttpCode.NOT_FOUND;
  } else if (status == 10002) {
    return AHttpCode.ERROR_10002;
  } else {
    return AHttpCode.FAILED;
  }
}
