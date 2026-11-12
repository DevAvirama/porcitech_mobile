import 'package:equatable/equatable.dart';

class SyncItemEntity extends Equatable {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final String description;
  final DateTime createdAt;

  const SyncItemEntity({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, endpoint, method, payload, description, createdAt];
}
