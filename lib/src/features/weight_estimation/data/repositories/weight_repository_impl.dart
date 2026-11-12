import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:porcitech_mobile/src/core/constants/api_constants.dart';
import 'package:porcitech_mobile/src/core/errors/exceptions.dart';
import 'package:porcitech_mobile/src/core/errors/failures.dart';
import 'package:porcitech_mobile/src/core/storage/local_cache_service.dart';
import 'package:porcitech_mobile/src/features/animals/data/models/porcino_model.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/data/datasources/weight_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/domain/entities/weight_record_entity.dart';
import 'package:porcitech_mobile/src/features/weight_estimation/domain/repositories/weight_repository.dart';

class WeightRepositoryImpl implements WeightRepository {
  final WeightRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  WeightRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, WeightRecordEntity>> registrarPesaje({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required double peso,
    required DateTime fecha,
    required String tipo,
    String? observaciones,
  }) async {
    final record = WeightRecordEntity(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      porcinoId: porcinoId,
      peso: peso,
      fecha: fecha,
      tipo: tipo,
    );

    final resolvedAnimalUuid = animalUuid ?? PorcinoModel.resolveUuid(porcinoId);
    final resolvedCorralUuid = corralUuid ?? PorcinoModel.resolveCorralUuid(porcinoId);
    final offlinePayload = <String, dynamic>{
      'id_cerdo': ?resolvedAnimalUuid,
      'corral_id': ?resolvedCorralUuid,
      'peso_kg': peso,
      'metodo': tipo.toLowerCase().contains('ia') ? 'ia_vision' : 'manual',
      'tiempo': fecha.toIso8601String(),
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.pesos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Pesaje porcino #$porcinoId: $peso kg ($tipo)',
      );
      return Right(record);
    }

    try {
      final remote = await remoteDataSource.registrarPesaje(
        porcinoId: porcinoId,
        animalUuid: resolvedAnimalUuid,
        corralUuid: resolvedCorralUuid,
        peso: peso,
        fecha: fecha,
        tipo: tipo,
        observaciones: observaciones,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: ApiConstants.pesos,
        method: 'POST',
        payload: offlinePayload,
        description: 'Pesaje porcino #$porcinoId: $peso kg ($tipo)',
      );
      return Right(record);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IaWeightEstimationResult>> estimarPesoPorIa({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required File imagenCenital,
    bool persistir = true,
  }) async {
    try {
      final result = await remoteDataSource.estimarPesoPorIa(
        porcinoId: porcinoId,
        animalUuid: animalUuid,
        corralUuid: corralUuid,
        imagenCenital: imagenCenital,
        persistir: persistir,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
