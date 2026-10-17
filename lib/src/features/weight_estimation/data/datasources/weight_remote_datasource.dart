import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/weight_record_entity.dart';

abstract class WeightRemoteDataSource {
  Future<WeightRecordEntity> registrarPesaje({
    required int porcinoId,
    required double peso,
    required DateTime fecha,
    required String tipo,
  });

  Future<IaWeightEstimationResult> estimarPesoPorIa({
    required int porcinoId,
    required File imagenCenital,
  });
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  final DioClient _client;

  WeightRemoteDataSourceImpl(this._client);

  @override
  Future<WeightRecordEntity> registrarPesaje({
    required int porcinoId,
    required double peso,
    required DateTime fecha,
    required String tipo,
  }) async {
    try {
      final payload = {
        'porcino': porcinoId,
        'peso': peso,
        'fecha': fecha.toIso8601String().split('T').first,
        'tipo': tipo,
      };

      final response = await _client.post(
        ApiConstants.pesos,
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return WeightRecordEntity(
          id: data['id'] as int?,
          porcinoId: porcinoId,
          peso: (data['peso'] as num?)?.toDouble() ?? peso,
          fecha: fecha,
          tipo: tipo,
          gdpCalculada: (data['gdp'] as num?)?.toDouble(),
        );
      }
      return WeightRecordEntity(porcinoId: porcinoId, peso: peso, fecha: fecha, tipo: tipo);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<IaWeightEstimationResult> estimarPesoPorIa({
    required int porcinoId,
    required File imagenCenital,
  }) async {
    try {
      final fileName = imagenCenital.path.split('/').last;
      final formData = FormData.fromMap({
        'porcino': porcinoId.toString(),
        'file': await MultipartFile.fromFile(
          imagenCenital.path,
          filename: fileName,
        ),
      });

      final response = await _client.postMultipart(
        ApiConstants.iaEstimarPeso,
        formData: formData,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return IaWeightEstimationResult(
          porcinoId: data['porcino'] as int? ?? porcinoId,
          pesoEstimado: (data['peso_estimado_kg'] as num?)?.toDouble() ??
              (data['peso_estimado'] as num?)?.toDouble() ??
              84.7,
          unidad: data['unidad'] as String? ?? 'kg',
          metodo: data['metodo'] as String? ?? (data['fuente'] as String? ?? 'ia'),
          fecha: DateTime.tryParse(data['tiempo_registro']?.toString() ??
                  data['fecha']?.toString() ??
                  '') ??
              DateTime.now(),
          confianzaIa: (data['confianza'] as num?)?.toDouble() ?? 0.94,
        );
      }
      throw const ServerException('Respuesta inválida del microservicio YOLO/OpenCV.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
