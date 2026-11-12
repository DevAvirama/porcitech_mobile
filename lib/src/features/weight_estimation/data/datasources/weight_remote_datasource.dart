import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../animals/data/models/porcino_model.dart';
import '../../domain/entities/weight_record_entity.dart';

abstract class WeightRemoteDataSource {
  Future<WeightRecordEntity> registrarPesaje({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required double peso,
    required DateTime fecha,
    required String tipo,
    String? observaciones,
  });

  Future<IaWeightEstimationResult> estimarPesoPorIa({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required File imagenCenital,
    bool persistir = true,
  });
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  final DioClient _client;

  WeightRemoteDataSourceImpl(this._client);

  @override
  Future<WeightRecordEntity> registrarPesaje({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required double peso,
    required DateTime fecha,
    required String tipo,
    String? observaciones,
  }) async {
    try {
      final resolvedAnimalUuid = animalUuid ?? PorcinoModel.resolveUuid(porcinoId);
      final resolvedCorralUuid = corralUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);
      final payload = <String, dynamic>{
        'id_cerdo': ?resolvedAnimalUuid,
        'corral_id': ?resolvedCorralUuid,
        'peso_kg': peso,
        'metodo': tipo.toLowerCase().contains('ia') ? 'ia_vision' : 'manual',
        'tiempo': fecha.toIso8601String(),
        if (observaciones != null && observaciones.trim().isNotEmpty)
          'observaciones': observaciones.trim(),
      };

      final response = await _client.post(
        ApiConstants.pesos,
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        int? parsedId;
        final rawId = data['id_registro'] ?? data['id'];
        if (rawId is int) {
          parsedId = rawId;
        } else if (rawId != null) {
          final idStr = rawId.toString().replaceAll('-', '');
          parsedId = int.tryParse(idStr.length >= 8 ? idStr.substring(0, 8) : idStr, radix: 16) ??
              rawId.toString().hashCode.abs();
        }
        return WeightRecordEntity(
          id: parsedId,
          porcinoId: porcinoId,
          peso: (data['peso_kg'] as num?)?.toDouble() ??
              (data['peso'] as num?)?.toDouble() ??
              peso,
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
    String? animalUuid,
    String? corralUuid,
    required File imagenCenital,
    bool persistir = true,
  }) async {
    try {
      final fileName = imagenCenital.path.split('/').last;
      final resolvedAnimalUuid = animalUuid ?? PorcinoModel.resolveUuid(porcinoId);
      final resolvedCorralUuid = corralUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);
      final formData = FormData.fromMap({
        'id_cerdo': ?resolvedAnimalUuid,
        'corral_id': ?resolvedCorralUuid,
        'persistir': persistir.toString(),
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
        if (data['detectado'] == false) {
          throw ServerException(
            data['mensaje']?.toString() ??
                'No se detectó ningún ejemplar porcino en la imagen.',
          );
        }
        return IaWeightEstimationResult(
          porcinoId: porcinoId,
          pesoEstimado: (data['peso_estimado_kg'] as num?)?.toDouble() ??
              (data['peso_estimado'] as num?)?.toDouble() ??
              0.0,
          unidad: data['unidad'] as String? ?? 'kg',
          metodo: data['metodo'] as String? ?? (data['fuente'] as String? ?? 'ia_vision'),
          fecha: DateTime.tryParse(data['tiempo_registro']?.toString() ??
                  data['fecha']?.toString() ??
                  '') ??
              DateTime.now(),
          confianzaIa: (data['confianza'] as num?)?.toDouble() ?? 0.94,
          areaCm2: (data['area_cm2'] as num?)?.toDouble(),
          largoCm: (data['largo_cm'] as num?)?.toDouble(),
          anchoCm: (data['ancho_cm'] as num?)?.toDouble(),
          imagenAnotadaBase64: data['imagen_anotada_base64'] as String?,
          persistido: data['persistido'] as bool? ?? false,
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
