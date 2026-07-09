import 'package:dio/dio.dart';

import '../config/api_config.dart';

const _publicAuthPaths = {
  '/v1/auth/login',
  '/v1/auth/refresh',
  '/v1/auth/logout',
};

class ApiClient {
  ApiClient(Future<String?> Function() readAccessToken)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeout,
          receiveTimeout: ApiConfig.timeout,
          sendTimeout: ApiConfig.timeout,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_publicAuthPaths.contains(options.path)) {
            handler.next(options);
            return;
          }
          final accessToken = await readAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
}