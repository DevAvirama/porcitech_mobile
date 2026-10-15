import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/core/theme/app_colors.dart';
import 'package:porcitech_mobile/src/core/widgets/tactile_button.dart';
import 'package:porcitech_mobile/src/features/auth/presentation/controllers/auth_controller.dart';

/// Pantalla de Inicio de Sesión de PorciTech (`inicio_de_sesion_porcitech`).
/// Optimizada para operarios en campo con campos táctiles grandes, isotipo corporativo
/// e interruptor de trabajo en Modo Offline para galpones sin cobertura.
class InicioDeSesionPorcitech extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const InicioDeSesionPorcitech({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  ConsumerState<InicioDeSesionPorcitech> createState() =>
      _InicioDeSesionPorcitechState();
}

class _InicioDeSesionPorcitechState
    extends ConsumerState<InicioDeSesionPorcitech> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'operario@porcitech.agro');
  final _passwordController = TextEditingController(text: 'Granja2026*');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isOffline = ref.watch(offlineModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Isotipo y Cabecera Corporativa ---
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.agriculture_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'PorciTech',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slateDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sistema Integral Porcino • Operaciones de Campo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slateMuted,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // --- Banner de Error si falló autenticación ---
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.alertRedLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.alertRedBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.alertRedDark,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.alertRedDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // --- Campo: Correo / Usuario del Operario ---
                    Text(
                      'Usuario o Correo Institucional',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slateDark,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'ej. operario@granja.co',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: AppColors.slateMuted,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese su correo o usuario asignado';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Campo: Contraseña ---
                    Text(
                      'Contraseña de Acceso',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slateDark,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.slateMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.slateMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Interruptor: Modo Offline de Granja ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isOffline ? AppColors.warningLight : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOffline
                              ? AppColors.warningOrange
                              : AppColors.slateBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                            color: isOffline
                                ? AppColors.warningOrange
                                : AppColors.primary,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modo Offline en Granja',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isOffline
                                        ? AppColors.warningOrange
                                        : AppColors.slateDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOffline
                                      ? 'Operando con base de datos local y cola offline'
                                      : 'Conectado a la API REST de FastAPI',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slateMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isOffline,
                            activeTrackColor: AppColors.warningOrange,
                            onChanged: (val) {
                              ref
                                  .read(offlineModeProvider.notifier)
                                  .toggleOffline(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Botón de 52px con Estado de Carga ---
                    TactileButton(
                      text: isOffline ? 'Ingresar en Modo Offline' : 'Iniciar Sesión en Granja',
                      icon: isOffline ? Icons.offline_pin_outlined : Icons.login_rounded,
                      isLoading: authState.isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'PorciTech v1.0.0 • Clean Architecture Flutter & FastAPI',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slateMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
