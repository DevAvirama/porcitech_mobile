import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/weight_record_entity.dart';

abstract class WeightRepository {
  Future<Either<Failure, WeightRecordEntity>> registrarPesaje({
    required int porcinoId,
    required double peso,
    required DateTime fecha,
    required String tipo,
  });

  Future<Either<Failure, IaWeightEstimationResult>> estimarPesoPorIa({
    required int porcinoId,
    required File imagenCenital,
  });
}
