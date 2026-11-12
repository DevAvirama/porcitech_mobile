import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_summary_entity.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardSummaryEntity>> getSummary();
}
