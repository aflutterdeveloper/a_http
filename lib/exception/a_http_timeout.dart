import 'a_http_exception.dart';

class AHttpTimeoutException extends AHttpException {
  AHttpTimeoutException(AHttpCode code, {String error})
      : super(code, error: error);

  @override
  String toString() {
    return "err:$code, msg:$error";
  }
}
