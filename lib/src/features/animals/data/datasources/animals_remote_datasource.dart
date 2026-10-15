import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/lote_model.dart';
import '../models/porcino_model.dart';

abstract class AnimalsRemoteDataSource {
  Future<List<PorcinoModel>> getPorcinos({String? query, String? filter});
  Future<PorcinoModel> getPorcinoById(int id);
  Future<PorcinoModel> getPorcinoByQr(String codigo);
  Future<PorcinoModel> createPorcino({
    required String codigo,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  });
  Future<List<LoteModel>> getLotes();
  Future<LoteModel> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
  });
}

class AnimalsRemoteDataSourceImpl implements AnimalsRemoteDataSource {
  final DioClient _client;

  AnimalsRemoteDataSourceImpl(this._client);

  @override
  Future<List<PorcinoModel>> getPorcinos({String? query, String? filter}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) queryParams['search'] = query;
      if (filter != null && filter != 'Todos') queryParams['fase'] = filter;

      final response = await _client.get(
        ApiConstants.porcinos,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((e) => PorcinoModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List)
            .map((e) => PorcinoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PorcinoModel> getPorcinoById(int id) async {
    try {
      final response = await _client.get(ApiConstants.porcinoById(id));
      if (response.data is Map<String, dynamic>) {
        return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const NotFoundException('Porcino no encontrado.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PorcinoModel> getPorcinoByQr(String codigo) async {
    try {
      final response = await _client.get(ApiConstants.porcinoByQr(codigo));
      if (response.data is Map<String, dynamic>) {
        return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const NotFoundException('El código QR o arete no coincide con ningún porcino activo.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PorcinoModel> createPorcino({
    required String codigo,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  }) async {
    try {
      final payload = {
        'codigo': codigo,
        'raza': raza,
        'sexo': sexo,
        'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
        'lote': loteId,
      };

      final response = await _client.post(
        ApiConstants.porcinos,
        data: payload,
      );

      if (response.data is Map<String, dynamic>) {
        return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerException('Respuesta inválida al registrar porcino.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<LoteModel>> getLotes() async {
    try {
      final response = await _client.get(ApiConstants.lotes);
      final data = response.data;
      if (data is List) {
        return data.map((e) => LoteModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List)
            .map((e) => LoteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<LoteModel> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.lotes,
        data: {
          'codigo': codigo,
          'nombre': nombre,
          'fase': fase,
          'galpon': galpon,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return LoteModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerException('Error al crear lote en FastAPI.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
