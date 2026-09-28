# EduSistem — Frontend

Plataforma académica de gestión y calificación para profesores. Frontend
Flutter (Web + Android) que consume el backend REST **EduSistem API**
(Spring Boot) mediante JWT.

Este repositorio contiene **solo el frontend**. El backend se desarrolla
por separado.

## Requisitos

- Flutter `3.41.6` (canal stable)
- Dart `3.11.4` (viene con el SDK de Flutter anterior)
- Chrome (para desarrollo web)
- Android SDK (para desarrollo/build de Android)

Verifica tu entorno con:

```bash
flutter doctor
```

## Instalación

```bash
flutter pub get
```

## Configuración de ambiente

La URL base de la API se inyecta en tiempo de build/ejecución mediante
`--dart-define-from-file`, no está hardcodeada en el código.

1. Copia la plantilla de desarrollo:

   ```bash
   cp env/development.json.example env/development.json
   ```

2. Edita `env/development.json` con la URL de tu backend local:

   ```json
   {
     "API_HOST": "http://localhost:8080",
     "ENVIRONMENT": "development"
   }
   ```

   - En **Android emulador**, `localhost` de tu máquina es
     `10.0.2.2`.
   - En un **dispositivo físico**, usa la IP de red local de tu máquina,
     por ejemplo `http://192.168.1.100:8080`.

3. Para producción, copia `env/production.json.example` a
   `env/production.json` y apunta al backend desplegado.

Los archivos `env/*.json` (reales) están en `.gitignore` — nunca se suben
al repositorio. Solo los `.example` se versionan.

## Ejecución

```bash
# Web (Chrome)
flutter run -d chrome --dart-define-from-file=env/development.json

# Android (emulador o dispositivo conectado)
flutter run --dart-define-from-file=env/development.json
```

## Build

```bash
# Web
flutter build web --dart-define-from-file=env/production.json

# Android (APK)
flutter build apk --dart-define-from-file=env/production.json

# Android (App Bundle, para Play Store)
flutter build appbundle --dart-define-from-file=env/production.json
```

## Testing

```bash
flutter analyze
flutter test
```

La suite de pruebas cubre:

- **Unit**: validadores (`Validators`) y formateadores (`Formatters`),
  incluyendo el redondeo de notas contra una escala arbitraria (nunca se
  asume `/5.0`).
- **Widget**: componentes críticos (`AppButton`) y el flujo de login
  (`LoginForm`), usando `mocktail` para simular `AuthRepository` sin
  golpear la red.

## Arquitectura

```
lib/
├── core/                  # Infraestructura transversal
│   ├── config/            # AppConfig (URL de API, timeouts, ambiente)
│   ├── constants/         # ApiEndpoints — únicas rutas REST del proyecto
│   ├── errors/            # AppException + mapeo de errores del backend
│   ├── extensions/        # Atajos de tema y notificaciones sobre BuildContext
│   ├── network/           # ApiClient (Dio) + refresh de JWT automático
│   ├── router/             # GoRouter, rutas centralizadas, navegación
│   ├── state/              # ListViewState/DetailViewState (Initial/Loading/
│   │                         Success/Empty/Error compartido por todos los
│   │                         providers de listado/detalle)
│   ├── storage/            # TokenStorage (flutter_secure_storage)
│   ├── theme/               # Paleta, tipografía, ThemeData centralizado
│   ├── layout/               # Breakpoints, ResponsiveBuilder y AppShell
│   ├── utils/                # Formatters, validators, descargas
│   └── widgets/
│       ├── shared/            # Primitivos neutrales (AppButton, AppFormFrame...)
│       ├── mobile/            # Solo mobile (MobileShell, MobileCardList...)
│       └── desktop/           # Solo desktop (DesktopShell, DesktopDataTable...)
│
├── features/                # Un directorio por dominio de negocio
│   ├── auth/                 # Login, registro, recuperación de contraseña
│   ├── dashboard/
│   ├── academic_levels/      # Catálogo "Grados" (10°, 11°...)
│   ├── subjects/              # Materias
│   ├── courses/                # Cursos/Grupos (10-A, 10-B...)
│   ├── academic_periods/        # Periodos académicos
│   ├── teaching/                 # Asignaciones profesor-materia-curso-periodo
│   ├── schedule/                 # Horario semanal por clase, agenda de hoy y calendario
│   ├── students/                  # Estudiantes, matrícula, retiro
│   ├── imports/                    # Importación de estudiantes por Excel
│   ├── exams/                       # Exámenes, preguntas, hojas PDF, submissions
│   ├── scanning/                     # Flujo de captura (cámara/drag&drop)
│   ├── grades/                        # Escalas, ponderaciones, notas del periodo
│   ├── activities/                     # Actividades y sus calificaciones
│   ├── attendance/                      # Sesiones de asistencia
│   ├── exports/                          # Exportación a Excel
│   ├── audit/                             # Historial de auditoría
│   └── profile/                            # Perfil y cambio de contraseña
│
└── main.dart                # Inyección de dependencias (Provider) + arranque
```

Cada feature sigue, cuando aporta valor real, la separación:

```
feature/
├── data/           # datasources (HTTP), models (JSON <-> entity), repositories
├── domain/         # entities (y, en auth, la interfaz de repository)
└── presentation/
    ├── pages/      # Punto de entrada: carga datos y elige la vista
    ├── mobile/     # Vista mobile
    ├── desktop/    # Vista desktop
    ├── shared/     # Formularios, acciones y controllers que usan ambas
    └── providers/  # Estado (ChangeNotifier)
```

**Sobre la capa de UseCase**: el flujo `Widget → Provider → Repository →
DataSource → HTTP` se respeta en todo el proyecto. Se añaden clases de
`UseCase` explícitas solo donde encapsulan lógica real más allá de una
llamada 1:1 al repositorio (por ejemplo, el flujo de autenticación). Para
catálogos CRUD simples (grados, materias, cursos, periodos), el provider
llama directamente al repositorio: envolver eso en un UseCase que solo
reenvía la llamada sería la abstracción "por moda" que el proyecto
explícitamente evita.

## Manejo de estado

`provider` (`ChangeNotifier`) en todo el proyecto — sin mezclar con
Riverpod/Bloc/GetX. Cada pantalla de listado/detalle expone su estado
como `ListViewState<T>` / `DetailViewState<T>`
(`core/state/list_state.dart`, `core/state/detail_state.dart`), que
modela explícitamente `Initial / Loading / Success / Empty / Error`.

## Mobile y desktop

Mobile y desktop **no** son el mismo layout estirado: cada pantalla tiene
una implementación propia en `mobile/` y otra en `desktop/`. Breakpoints
en `core/layout/responsive.dart`:

- **Mobile**: `< 600px` — bottom navigation, cards, cámara, formularios a
  pantalla completa.
- **Tablet**: `600–1024px` — familia desktop con `NavigationRail`.
- **Desktop/Web**: `≥ 1024px` — sidebar colapsable, tablas, diálogos,
  drag & drop.

Reglas:

- `ResponsiveBuilder` se usa **solo** en el punto de entrada de cada
  página (`pages/`) y en `AppShell`. Debajo de ese punto ningún widget
  pregunta "¿estoy en mobile?" (no existe `context.isMobile`).
- Lo que no depende de la plataforma (formularios, acciones con su
  feedback, controllers de estado, etiquetas) vive en `shared/` y lo usan
  ambas vistas. La lógica de negocio sigue en providers/repositorios.
- El estado que debe sobrevivir a un cambio de tamaño (clase elegida,
  filtros, borradores, archivos seleccionados) vive en la página de
  entrada o en un controller de `shared/`, nunca dentro de una vista.
- Los formularios usan `AppFormFrame`; la vista decide cómo presentarlos:
  `showDesktopDialog` en desktop, `showMobileForm`/`showMobileSheet` en
  mobile.

## Seguridad

- El JWT se guarda con `flutter_secure_storage` (Android: Keystore; Web:
  clave `CryptoKey` no exportable en IndexedDB, más allá de
  `localStorage` plano).
- El token nunca se imprime ni se loguea.
- El refresco de sesión (401 → `/auth/refresh` → reintento) es
  automático y transparente (`AuthInterceptor`); si el refresh falla, la
  sesión se cierra localmente y el usuario es redirigido a `/login`
  (`AppRouter` reacciona a `AuthProvider` como `refreshListenable`).
- El frontend **nunca** es la autoridad de permisos: solo adapta la UI.
  El backend protege cada endpoint independientemente de lo que la
  interfaz muestre u oculte.

## Dependencias principales

| Paquete                  | Uso                                            |
|---------------------------|-------------------------------------------------|
| `provider`                 | Manejo de estado                                 |
| `dio`                       | Cliente HTTP centralizado (`ApiClient`)           |
| `go_router`                  | Enrutamiento declarativo + guards de sesión        |
| `flutter_secure_storage`      | Persistencia segura del JWT                         |
| `file_picker` / `desktop_drop` | Selección de archivos y drag & drop (desktop/web)    |
| `image_picker`                   | Captura de fotos con la cámara (escaneo, mobile)      |
| `file_saver`                       | Descarga de PDFs/Excel multiplataforma (web/Android)    |
| `intl`                               | Formato de fechas                                        |
| `mocktail` (dev)                      | Mocks para tests de widgets                                |

## Dependencias del backend (endpoints usados)

El contrato completo está documentado en el código (`ApiEndpoints`) y
replica exactamente el contrato provisto por el equipo de backend
(`/api/v1`, JWT, paginación `[PAGE]`, envelope de errores estándar). No
se inventó ningún endpoint; donde el backend aún no expone un dato (por
ejemplo, un endpoint agregado de estadísticas de dashboard), el frontend
compone la información a partir de los endpoints existentes en lugar de
mockearla permanentemente.
