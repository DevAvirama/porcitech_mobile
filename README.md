# 📱 PorciTech Mobile — Módulo Móvil Offline-First

Aplicación móvil desarrollada en **Flutter** diseñada para la recolección, auditoría y control de operaciones en campo para granjas porcícolas. Forma parte integral del ecosistema **PorciTech**, complementando la plataforma central [PorciTech Web](https://github.com/DevAvirama/porcitech-nextjs).

---

## 🌾 Contexto y Enfoque Offline-First

En la producción porcícola, gran parte del trabajo operativo (galpones, corrales de gestación, maternidad y básculas de pesaje) ocurre en zonas rurales con conectividad celular o Wi-Fi nula o intermitente.

**PorciTech Mobile** implementa un modelo **Offline-First**, donde el dispositivo móvil opera como nodo transaccional autónomo:
1. **Operación Local Ininterrumpida:** Todos los eventos de campo (pesajes, partos, vacunaciones, traslados) se persisten localmente en el dispositivo de inmediato sin requerir conexión a internet.
2. **Cola de Sincronización (Sync Queue):** Las mutaciones se encolan con marcas temporales (timestamps UTC) e identificadores idempotentes (UUIDs).
3. **Sincronización Bidireccional Inteligente:** Al restablecerse la conectividad, el motor en segundo plano sincroniza las novedades contra la API central de PorciTech y descarga las actualizaciones de stock, alertas y directrices veterinarias.

---

## 🚀 Funcionalidades Principales

* 🏷️ **Identificación Rápida y Trazabilidad:** Lectura de códigos QR y códigos de arete visual para acceder al expediente zootécnico del animal al instante.
* ⚖️ **Control de Pesaje en Sitio:** Captura rápida del peso de animales individuales o por lotes, calculando variaciones respecto al pesaje anterior.
* 🧪 **Sanidad y Tratamientos en Corral:** Registro de aplicación de vacunas, desparasitaciones y antibióticos con control de tiempos de retiro.
* 🧬 **Manejo Reproductivo:** Registro de servicios/inseminaciones, diagnóstico de preñez y atención de partos (lechones nacidos vivos, muertos o momias).
* 🔄 **Monitoreo de Estado de Sincronización:** Indicadores visuales en la interfaz del estado de la cola de sincronización y alertas de conflictos.

---

## 🛠️ Stack Tecnológico

| Componente | Tecnología / Especificación |
| :--- | :--- |
| **Framework** | Flutter (Dart SDK `^3.12.2`) |
| **Diseño** | Material Design 3 con contraste optimizado para campo |
| **Arquitectura** | Domain-Driven Design / Clean Architecture móvil |
| **Almacenamiento Local** | Persistencia local offline-first con soporte transaccional |
| **Sincronización** | Cliente HTTP con cola de reintentos y tokens de autorización JWT |

---

## 📂 Estructura del Proyecto

```text
porcitech_mobile/
├── android/               # Configuración de compilación para Android
├── ios/                   # Configuración para iOS
├── lib/                   # Código fuente de la aplicación Flutter
│   └── main.dart          # Punto de entrada de la aplicación
├── pubspec.yaml           # Manifiesto de paquetes y dependencias de Flutter
├── analysis_options.yaml  # Reglas de linting y análisis estático (flutter_lints)
└── README.md              # Documentación técnica del módulo móvil
```

---

## ⚙️ Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de contar con:

* **Flutter SDK:** Versión `>= 3.12.0` ([Instrucciones de instalación](https://docs.flutter.dev/get-started/install))
* **Dart SDK:** Incluido con Flutter.
* **Android Studio** (con Android SDK y emulador configurado) o dispositivo físico Android con *Depuración USB* activada.
* **Xcode** (opcional, requerido para compilar en macOS hacia iOS).

Verifica tu entorno ejecutando:
```bash
flutter doctor
```

---

## 🏃 Instalación y Ejecución

### 1. Clonar el repositorio
```bash
git clone git@github.com:DevAvirama/porcitech_mobile.git
cd porcitech_mobile
```

### 2. Descargar paquetes y dependencias
```bash
flutter pub get
```

### 3. Ejecutar en modo desarrollo
Inicia un emulador o conecta un dispositivo físico y ejecuta:
```bash
flutter run
```

Durante la ejecución, pulsa:
* `r` para realizar **Hot Reload** (recarga rápida de cambios visuales).
* `R` para realizar **Hot Restart** (reinicio del estado de la aplicación).
* `q` para detener la sesión.

### 4. Compilación para Producción

* **Generar APK para Android:**
  ```bash
  flutter build apk --release
  ```
  El artefacto resultante se ubicará en `build/app/outputs/flutter-apk/app-release.apk`.

* **Generar Android App Bundle (AAB para Google Play):**
  ```bash
  flutter build appbundle --release
  ```

---

## 🤝 Integración en el Ecosistema PorciTech

```text
 ┌────────────────────────────────────────┐
 │           PorciTech Web               │  (Next.js Dashboard Central)
 └───────────────────▲────────────────────┘
                     │ (HTTPS / REST API)
 ┌───────────────────▼────────────────────┐
 │         Sync Engine / API             │
 └───────────────────▲────────────────────┘
                     │ (Sincronización automática periódica)
 ┌───────────────────▼────────────────────┐
 │        PorciTech Mobile (Flutter)     │  ◄── Operación Offline en Granja
 └────────────────────────────────────────┘
```

---

## 📄 Licencia y Mantenimiento

Desarrollado y mantenido por [Santiago Avirama (DevAvirama)](https://github.com/DevAvirama). Parte del proyecto **PorciTech**.
