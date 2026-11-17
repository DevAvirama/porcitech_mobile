import 'package:equatable/equatable.dart';

enum SyncItemStatus {
  pendiente,
  enviado,
  error,
  conflicto;

  static SyncItemStatus fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'enviado':
        return SyncItemStatus.enviado;
      case 'error':
        return SyncItemStatus.error;
      case 'conflicto':
        return SyncItemStatus.conflicto;
      default:
        return SyncItemStatus.pendiente;
    }
  }
}

class SyncItemEntity extends Equatable {
  final String id;
  final String idLocal;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final String description;
  final SyncItemStatus status;
  final String? errorMessage;
  final int retryCount;
  final String? filePath;
  final DateTime createdAt;

  const SyncItemEntity({
    required this.id,
    String? idLocal,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.description,
    this.status = SyncItemStatus.pendiente,
    this.errorMessage,
    this.retryCount = 0,
    this.filePath,
    required this.createdAt,
  }) : idLocal = idLocal ?? id;

  @override
  List<Object?> get props => [
        id,
        idLocal,
        endpoint,
        method,
        payload,
        description,
        status,
        errorMessage,
        retryCount,
        filePath,
        createdAt,
      ];
}
