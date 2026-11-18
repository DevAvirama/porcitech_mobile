import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';

/// Verifica y solicita el permiso de cámara en tiempo de ejecución.
/// Si fue denegado permanentemente, ofrece abrir los ajustes de la app.
Future<bool> ensureCameraPermission(BuildContext context) async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;

  status = await Permission.camera.request();
  if (status.isGranted) return true;

  if (!context.mounted) return false;

  if (status.isPermanentlyDenied || status.isRestricted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Permiso de Cámara Requerido',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'PorciTech necesita acceso a la cámara para escanear códigos QR y tomar fotografías de pesaje. Activa el permiso desde Ajustes.',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.senaGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes permitir el acceso a la cámara para usar esta función.'),
        backgroundColor: AppColors.alertRedDark,
      ),
    );
  }
  return false;
}
