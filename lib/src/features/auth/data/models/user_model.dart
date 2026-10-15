import '../../domain/entities/user_entity.dart';

/// Modelo de datos para serialización/deserialización de respuesta JWT de FastAPI.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.granja,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'] as int? ?? 1,
      email: json['email'] as String? ?? 'operario@porcitech.agro',
      name: json['name'] as String? ?? json['username'] as String? ?? 'Operario Granja',
      role: json['role'] as String? ?? 'operario',
      granja: json['granja'] as String? ?? 'Granja San Jerónimo - Galpón 4',
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'granja': granja,
      'token': token,
    };
  }
}
