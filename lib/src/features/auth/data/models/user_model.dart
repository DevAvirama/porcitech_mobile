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
    int parsedId = 1;
    final rawId = json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      final idStr = rawId.toString().trim();
      final asInt = int.tryParse(idStr);
      if (asInt != null) {
        parsedId = asInt;
      } else {
        final hexClean = idStr.replaceAll('-', '');
        if (hexClean.length >= 8) {
          parsedId = int.tryParse(hexClean.substring(0, 8), radix: 16) ?? idStr.hashCode.abs();
        } else if (idStr.isNotEmpty) {
          parsedId = idStr.hashCode.abs();
        }
      }
    }

    final nombre = json['nombre']?.toString().trim() ?? '';
    final apellido = json['apellido']?.toString().trim() ?? '';
    final fullName = '$nombre $apellido'.trim();

    return UserModel(
      id: parsedId,
      email: json['email'] as String? ?? 'operario@porcitech.agro',
      name: fullName.isNotEmpty
          ? fullName
          : (json['name'] as String? ?? json['username'] as String? ?? 'Operario Granja'),
      role: json['rol'] as String? ?? json['role'] as String? ?? 'operario',
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
