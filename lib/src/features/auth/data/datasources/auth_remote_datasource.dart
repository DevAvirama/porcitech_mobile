import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await _client.post(
        ApiConstants.loginToken,
        data: {
          'username': email,
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final token = (data['access_token'] ?? data['token'] ?? '') as String;
        final rawUser = data['usuario'] ?? data['user'];
        final userData = (rawUser is Map<String, dynamic>)
            ? rawUser
            : data;

        return UserModel.fromJson(userData, token);
      }
      throw const ServerException('Formato de respuesta inesperado del servidor.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
