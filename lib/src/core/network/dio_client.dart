import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'network_info.dart';

/// Cliente HTTP centralizado para PorciTech basado en Dio.
/// Comunica la aplicación móvil exclusivamente con la API REST de FastAPI.
class DioClient {
  final Dio _dio;
  final NetworkInfo networkInfo;

  DioClient({
    Dio? dio,
    required SecureStorageService secureStorage,
    required this.networkInfo,
    String? baseUrl,
    void Function()? onSessionExpired,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.defaultBaseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                sendTimeout: ApiConstants.sendTimeout,
                responseType: ResponseType.json,
                headers: {
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      AuthInterceptor(
        secureStorage: secureStorage,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  Dio get rawDio => _dio;

  /// Petición GET tipada con control de conectividad y mapeo a AppException.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkNetwork();
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Petición POST tipada con soporte para JSON.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkNetwork();
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Petición POST para subida de archivos (visión artificial YOLO/OpenCV).
  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await _checkNetwork();
    try {
      final response = await _dio.post<T>(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Petición PUT.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkNetwork();
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Petición DELETE.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkNetwork();
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> _checkNetwork() async {
    final connected = await networkInfo.isConnected;
    if (!connected) {
      throw const NoInternetException('Dispositivo sin conexión a la red de granja.');
    }
  }

  AppException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NoInternetException('Tiempo de espera agotado. Verifique la antena o router en el galpón.');
    }

    final statusCode = error.response?.statusCode;
    final dynamic responseData = error.response?.data;
    String message = 'Ocurrió un error en la comunicación con FastAPI.';

    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('detail')) {
        final detail = responseData['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          // Errores de validación Pydantic de FastAPI
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            message = first['msg'].toString();
          }
        }
      } else if (responseData.containsKey('message')) {
        message = responseData['message'].toString();
      }
    }

    switch (statusCode) {
      case HttpStatus.badRequest:
        return BadRequestException(message, statusCode);
      case HttpStatus.unauthorized:
        return UnauthorizedException(message, statusCode);
      case HttpStatus.forbidden:
        return ForbiddenException(message, statusCode);
      case HttpStatus.notFound:
        return NotFoundException(message, statusCode);
      case HttpStatus.internalServerError:
      case HttpStatus.badGateway:
      case HttpStatus.serviceUnavailable:
        return ServerException(message, statusCode);
      default:
        return ServerException(message, statusCode);
    }
  }
}
