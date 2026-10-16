import 'package:porcitech_mobile/src/core/network/dio_client.dart';
import '../models/lote_model.dart';
import '../models/porcino_model.dart';

abstract class AnimalsRemoteDataSource {
  Future<List<PorcinoModel>> getPorcinos({String? query, String? filter});
  Future<PorcinoModel> getPorcinoById(int id);
  Future<PorcinoModel> createPorcino({
    required String codigo,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  });
  Future<PorcinoModel> getPorcinoByQr(String codigo);
  Future<List<LoteModel>> getLotes();
  Future<LoteModel> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
  });
}

class AnimalsRemoteDataSourceImpl implements AnimalsRemoteDataSource {
  final DioClient dioClient;

  AnimalsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<PorcinoModel>> getPorcinos({String? query, String? filter}) async {
    final Map<String, dynamic> queryParams = {};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }

    final response = await dioClient.get(
      '/api/porcinos/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final list = response.data as List;
    return list.map((json) => PorcinoModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<PorcinoModel> getPorcinoById(int id) async {
    final response = await dioClient.get('/api/porcinos/$id/');
    return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PorcinoModel> createPorcino({
    required String codigo,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  }) async {
    final response = await dioClient.post('/api/porcinos/', data: {
      'codigo': codigo,
      'raza': raza,
      'sexo': sexo,
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'lote_id': loteId,
    });
    return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PorcinoModel> getPorcinoByQr(String codigo) async {
    final response = await dioClient.get('/api/porcinos/qr/$codigo/');
    return PorcinoModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<LoteModel>> getLotes() async {
    final response = await dioClient.get('/api/lotes/');
    final list = response.data as List;
    return list.map((json) => LoteModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<LoteModel> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
  }) async {
    final response = await dioClient.post('/api/lotes/', data: {
      'codigo': codigo,
      'nombre': nombre,
      'fase': fase,
      'galpon': galpon,
    });
    return LoteModel.fromJson(response.data as Map<String, dynamic>);
  }
}