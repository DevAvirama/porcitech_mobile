import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/weight_record_entity.dart';

abstract class WeightRepository {
  Future<Either<Failure, WeightRecordEntity>> registrarPesaje({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required double peso,
    required DateTime fecha,
    required String tipo,
    String? observaciones,
  });

  Future<Either<Failure, IaWeightEstimationResult>> estimarPesoPorIa({
    required int porcinoId,
    String? animalUuid,
    String? corralUuid,
    required File imagenCenital,
    bool persistir = true,
  });
}
