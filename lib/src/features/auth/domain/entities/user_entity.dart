import 'package:equatable/equatable.dart';

/// Entidad inmutable que representa al operario, zootecnista o administrador autenticado.
class UserEntity extends Equatable {
  final int id;
  final String email;
  final String name;
  final String role; // 'operario', 'zootecnista', 'administrador'
  final String? granja;
  final String token;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.granja,
    required this.token,
  });

  @override
  List<Object?> get props => [id, email, name, role, granja, token];
}
