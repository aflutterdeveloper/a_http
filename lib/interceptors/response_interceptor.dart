import 'package:autility/utility/serializable.dart';
import 'package:dio/dio.dart';

class ResponseInterceptor<T> extends InterceptorsWrapper {
  ResponseInterceptor(Serializable<T> serializable)
      : super(onResponse: (Response response) async {
          int statusCode = response?.statusCode ?? -1;
          T data;
          if (null != response) {
            if (statusCode >= 200 && statusCode < 300) {
              data = serializable.deserialize(response.data);
            }
          }
          return Response<T>(
            data: data,
            headers: response.headers,
            request: response.request,
            statusCode: statusCode,
            isRedirect: response.isRedirect,
            redirects: response.redirects,
            statusMessage: response.statusMessage,
          );
        });
}
