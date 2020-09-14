import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:a_thread_pool/a_thread_pool.dart';
import 'package:autility/autility.dart';
import 'package:autility/utility/a_log.dart';
import 'package:autility/utility/serializable.dart';
import 'package:dio/dio.dart';

import 'a_http_client_adapter.dart';
import 'exception/a_http_exception.dart';
import 'i_header_provider.dart';
import 'interceptors/i_interceptor_provider.dart';
import 'interceptors/response_interceptor.dart';
import 'transform/a_http_transformer.dart';

class AHttp {
  static const _TAG = "AHttp";
  static ThreadPool _httpPool = ThreadPool.build(
      max(4, (Platform.numberOfProcessors * 0.6).floor()), "a_http");
  static ThreadPool _downloadPool = ThreadPool.build(
      max(4, (Platform.numberOfProcessors * 0.4).floor()), "a_download");

  static bool _devMode = false;
  static String _defaultHost;
  static String _defaultProxy;
  static IHeaderProvider _headerProvider;
  static IInterceptorProvider _interceptorProvider;

  static set devMode(bool devMode) {
    _devMode = devMode;
  }

  static void init(
      {String defaultHost,
      String proxy,
      IHeaderProvider headerProvider,
      IInterceptorProvider interceptorProvider}) {
    _defaultHost = defaultHost;
    _defaultProxy = proxy;
    _interceptorProvider = interceptorProvider;
    _headerProvider = headerProvider;
  }

  static Future<Map<String, dynamic>> _getHeader(
      IHeaderProvider provider) async {
    if (null != provider) {
      return await provider.header;
    }

    if (_headerProvider != null) {
      return await _headerProvider.header;
    }
    return Map<String, dynamic>();
  }

  // throw HttpException on failed
  static Future<T> get<T>(String url,
      {Map<String, dynamic> params = const {},
      Serializable<T> serializable,
      IHeaderProvider provider}) async {
    await _checkNetwork();

    String host = _defaultHost;
    String path = url;
    if (url.startsWith("http")) {
      final uri = Uri.parse(url);
      path = uri.path;
      host = "${uri.scheme}://${uri.host}";
    }

    _Request<T> req = _Request<T>(
        host, path, params, await _getHeader(provider), serializable);

    ALog.info(_TAG, "getting $url");
    _DioResponse response;
    try {
      response = await _httpPool.run(_processGetHttp, req);
      ALog.info(_TAG, "get finish ${response.code} $url");
    } catch (e, stack) {
      ALog.error("AHttp", "get $e, $stack");
      throw _error(e);
    }

    if (response.code.index != AHttpCode.SUCCEED.index) {
      throw AHttpException(response.code);
    }
    return response.data;
  }

  static Future<T> postForm<T>(String url,
      {Map<String, dynamic> params = const {},
      Map<String, dynamic> form,
      IHeaderProvider provider,
      Serializable<T> serializable}) async {
    String data;
    if (form != null) {
      data = "";
      form.forEach((key, value) {
        if (data.isNotEmpty) {
          data += '&';
        }
        data += "$key=$value";
      });
    }
    return await _post(url,
        params: params,
        data: data,
        provider: provider,
        isFormData: true,
        serializable: serializable);
  }

  static Future<T> post<T>(String url,
      {Map<String, dynamic> params = const {},
      String data,
      IHeaderProvider provider,
      Serializable<T> serializable}) async {
    return await _post(url,
        params: params,
        data: data,
        isFormData: false,
        provider: provider,
        serializable: serializable);
  }

  // throw HttpException on failed
  static Future<T> _post<T>(String url,
      {Map<String, dynamic> params = const {},
      dynamic data,
      bool isFormData = false,
      IHeaderProvider provider,
      Serializable<T> serializable}) async {
    await _checkNetwork();

    String host = _defaultHost;
    String path = url;
    if (url.startsWith("http")) {
      final uri = Uri.parse(url);
      path = uri.path;
      host = "${uri.scheme}://${uri.host}";
    }

    _PostReq<T> req = _PostReq<T>(host, path, params, data, isFormData,
        await _getHeader(provider), serializable);

    ALog.info(_TAG, "posting $url");
    _DioResponse response;
    try {
      response = await _httpPool.run(_processPostHttp, req);
      ALog.info(_TAG, "post finish ${response.code} $url");
    } catch (e, stack) {
      ALog.error("AHttp", "post $e $stack");
      throw _error(e);
    }

    if (response.code.index != AHttpCode.SUCCEED.index) {
      ALog.info(_TAG,
          "post finish exception ${response.code} ${response.code == AHttpCode.SUCCEED} $url");
      throw AHttpException(response.code);
    }
    return response.data;
  }

  // throw HttpException on failed
  static Future<T> put<T>(String url,
      {Map<String, dynamic> params = const {},
      dynamic data = const {},
      bool isFormData = false,
      IHeaderProvider provider,
      Serializable<T> serializable}) async {
    await _checkNetwork();

    String host = _defaultHost;
    String path = url;
    if (url.startsWith("http")) {
      final uri = Uri.parse(url);
      path = uri.path;
      host = "${uri.scheme}://${uri.host}";
    }

    _ModifyRequestReq<T> req = _ModifyRequestReq<T>(host, path, params, data,
        isFormData, await _getHeader(provider), serializable, _devMode);

    ALog.info(_TAG, "puting $url");
    _DioResponse response;
    try {
      response = await _httpPool.run(_processPutHttp, req);
      ALog.info(_TAG, "puting finish ${response.code} $url");
    } catch (e, stack) {
      ALog.error("AHttp", "put $e  $stack");
      throw _error(e);
    }

    if (response.code.index != AHttpCode.SUCCEED.index) {
      throw AHttpException(response.code);
    }
    return response.data;
  }

  // throw HttpException on failed
  static Future<T> delete<T>(String url,
      {Map<String, dynamic> params,
      Map<String, dynamic> data,
      IHeaderProvider provider,
      Serializable<T> serializable}) async {
    await _checkNetwork();

    String host = _defaultHost;
    String path = url;
    if (url.startsWith("http")) {
      final uri = Uri.parse(url);
      path = uri.path;
      host = "${uri.scheme}://${uri.host}";
    }

    _ModifyRequestReq<T> req = _ModifyRequestReq<T>(host, path, params, data,
        false, await _getHeader(provider), serializable, _devMode);

    ALog.info(_TAG, "deleting $url");
    _DioResponse response;
    try {
      response = await _httpPool.run(_processDeleteHttp, req);
      ALog.info(_TAG, "deleting finish ${response.code} $url");
    } catch (e, stack) {
      ALog.error("AHttp", "delete $e $stack");
      throw _error(e);
    }

    if (response.code.index != AHttpCode.SUCCEED.index) {
      throw AHttpException(response.code);
    }
    return response.data;
  }

  static Future<AHttpCode> download(String url, String savePath,
      [Map<String, dynamic> params]) async {
    await _checkNetwork();

    ALog.info(_TAG, "downloading $url");
    _checkParam(url);

    try {
      final result = await _downloadPool.run(
          _processDownloadHttp, _DownloadReq(url, savePath, params, _devMode));

      ALog.info(_TAG, "download finish $result $url");
      if (result.index != AHttpCode.SUCCEED.index) {
        throw AHttpException(result);
      }
      return result;
    } catch (error, stack) {
      ALog.error("AHttp", "download $error $stack");
      throw _error(error);
    }
  }

  static void _checkParam(String url) {
    if (url?.isNotEmpty != true) {
      throw AHttpException(AHttpCode.PARAM_ERROR);
    }
  }

  static Future _checkNetwork() async {
    if (!await NetUtil.hasNetwork()) {
      throw AHttpException(AHttpCode.NETWORK_FAIL);
    }
  }

  static Future<Dio> _requestDio<T>(
      params,
      data,
      bool isFormData,
      Map<String, dynamic> headers,
      Serializable<T> serializable,
      bool devEnable,
      String host,
      String proxy) async {
    if (isFormData) {
      headers['Content-Type'] =
          'application/x-www-form-urlencoded;charset=utf-8';
    } else {
      headers['Content-Type'] = 'application/json;charset=utf-8';
    }

    BaseOptions requestOptions = new BaseOptions(
        baseUrl: host,
        connectTimeout: 10000,
        receiveTimeout: 10000,
        headers: headers);
    Dio dio = new Dio(requestOptions); //x with default Options

    dio.httpClientAdapter = AHttpClientAdapter(devEnable, proxy);
    dio.transformer = AHttpTransformer();
    final interceptors = await _interceptorProvider?.interceptors;
    if (interceptors?.isNotEmpty == true) {
      dio.interceptors.addAll(interceptors);
    }
    dio.interceptors.add(ResponseInterceptor(serializable));
    return dio;
  }
}

FutureOr<_DioResponse> _processGetHttp<T>(_Request req) async {
  final dio = await AHttp._requestDio(req.params, null, false, req.headers,
      req.serializable, req.devEnable, req.host, req.proxy);
  final response = await dio.get<T>(req.method, queryParameters: req.params);

  return _responseData<T>(response);
}

FutureOr<_DioResponse> _processPostHttp<T>(_PostReq req) async {
  final dio = await AHttp._requestDio(req.params, req.data, req.isFormData,
      req.headers, req.serializable, req.devEnable, req.host, req.proxy);
  final response = await dio.post<T>(req.method,
      queryParameters: req.params, data: req.data);

  return _responseData<T>(response);
}

FutureOr<_DioResponse> _processPutHttp<T>(_ModifyRequestReq req) async {
  final dio = await AHttp._requestDio(req.params, req.data, req.isFormData,
          req.headers, req.serializable, req.devEnable, req.host, req.proxy)
      .catchError((error) {});
  final response =
      await dio.put(req.method, data: req.data, queryParameters: req.params);
  return _responseData<T>(response);
}

FutureOr<_DioResponse> _processDeleteHttp<T>(_ModifyRequestReq req) async {
  final dio = await AHttp._requestDio(req.params, null, false, req.headers,
      req.serializable, req.devEnable, req.host, req.proxy);
  final response =
      await dio.delete(req.method, data: req.data, queryParameters: req.params);
  return _responseData<T>(response);
}

dynamic _error(dynamic err) {
  if (err is DioError) {
    if (err.response != null) {
      return AHttpException(statusCode2HttpCode(err.response.statusCode));
    }
  } else if (err is AException || err is AHttpException) {
    return err;
  }
  return AHttpException(AHttpCode.FAILED);
}

_DioResponse<T> _responseData<T>(Response response) {
  final statusCode = response?.statusCode ?? -1;
  return _DioResponse<T>(statusCode2HttpCode(statusCode), response.data);
}

FutureOr<AHttpCode> _processDownloadHttp<T>(_DownloadReq req) async {
  BaseOptions requestOptions = new BaseOptions(
    connectTimeout: 10000,
    receiveTimeout: 10000,
  );

  final response = await Dio(requestOptions)
      .download(req.url, req.savePath, deleteOnError: true)
      .catchError((error) {
    if (error is DioError) {
      return error.response;
    }
    ALog.info("AHttp", "_processDownloadHttp $error");
    return error;
  });
  final statusCode = response?.statusCode ?? -1;
  ALog.info("AHttp", "_processDownloadHttp $statusCode");
  return statusCode2HttpCode(statusCode);
}

class _Request<T> {
  _Request(
      this.host, this.method, this.params, this.headers, this.serializable);

  Map<String, dynamic> headers;
  String method;
  String host;
  Map<String, dynamic> params;
  Serializable<T> serializable;
  bool devEnable = AHttp._devMode;
  String proxy = AHttp._defaultProxy;
}

class _PostReq<T> extends _Request<T> {
  _PostReq(host, method, params, data, bool isFormData, headers, serializable)
      : this.data = data,
        this.isFormData = isFormData,
        super(host, method, params, headers, serializable);

  dynamic data;
  bool isFormData;
}

class _ModifyRequestReq<T> extends _Request<T> {
  _ModifyRequestReq(host, method, params, data, bool isFormData, headers,
      serializable, devEnable)
      : this.data = data,
        this.isFormData = isFormData,
        super(host, method, params, headers, serializable);
  dynamic data;
  bool isFormData;
}

class _DownloadReq {
  _DownloadReq(this.url, this.savePath, this.params, this.devEnable);

  final String url;
  final String savePath;
  final Map<String, dynamic> params;
  final devEnable;
}

class _DioResponse<T> {
  _DioResponse(this.code, this.data);

  final AHttpCode code;
  final T data;
}
