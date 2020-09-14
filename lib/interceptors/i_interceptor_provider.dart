import 'package:dio/dio.dart';

abstract class IInterceptorProvider {
  Future<List<InterceptorsWrapper>> get interceptors;
}
