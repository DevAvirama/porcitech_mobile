import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/porcino_entity.dart';

abstract class AnimalsRepository {
  Future<Either<Failure, List<PorcinoEntity>>> getPorcinos({
    String? query,
    String? filter,
  });

  Future<Either<Failure, PorcinoEntity>> getPorcinoById(int id);

  Future<Either<Failure, PorcinoEntity>> getPorcinoByQr(String codigo);

  Future<Either<Failure, PorcinoEntity>> createPorcino({
    required String codigo,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  });

  Future<Either<Failure, List<LoteEntity>>> getLotes();

  Future<Either<Failure, LoteEntity>> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
  });
}
