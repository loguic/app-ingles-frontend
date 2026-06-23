# Bitácora del frontend app_ingles

## B59 — Creación inicial del proyecto Flutter

- Objetivo: crear la base inicial del frontend Flutter para app-ingles.
- Entorno:
  - Ubuntu VMware.
  - Flutter 3.41.6.
  - Dart 3.11.4.
- Proyecto creado:
  - ~/projects/app_ingles_frontend/app_ingles
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B63 - Pantalla inicial del frontend

- Objetivo: crear una pantalla inicial básica para la app de aprendizaje de inglés.
- Archivo modificado:
  - lib/main.dart
- Cambio realizado:
  - Se reemplaza la estructura inicial generada por Flutter por una pantalla base del proyecto app_ingles.
  - Se ajusta el test inicial para usar el widget principal correcto.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.
- Commit:
  - 53cd546 - B63 create initial App Ingles home screen

## B64 - Dependencia HTTP para conexión con backend

- Objetivo: preparar el frontend para realizar peticiones HTTP al backend FastAPI.
- Archivo modificado:
  - pubspec.yaml
  - pubspec.lock
- Cambio realizado:
  - Se agreg? la dependencia http 1.6.0.
- Problema que resuelve:
  - Permite que Flutter pueda comunicarse con la API del backend mediante HTTP.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.
- Commit:
  - c791b5f - B64 add http dependency

## B67 - ApiService b?sico para health check

- Objetivo: crear una capa inicial de servicio para conectar el frontend Flutter con el backend FastAPI.
- Archivo creado:
  - lib/services/api_service.dart
- Cambio realizado:
  - Se creó la carpeta lib/services.
  - Se creó ApiService con baseUrl apuntando a http://192.168.1.33:8000/api/v1.
  - Se implementó el método checkHealth().
  - Se usó package:http/http.dart para realizar la petición HTTP.
  - Se usó jsonDecode para interpretar la respuesta del backend.
- Problema que resuelve:
  - Centraliza la comunicaci?n inicial con el backend y evita mezclar lógica HTTP directamente en la interfaz.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.
- Estado Git/GitHub:
  - Commit y push realizados.
  - git status limpio en master...origin/master.

## B68 - Decisión de entorno profesional con VS Code Remote SSH

- Objetivo: mejorar el flujo de trabajo del frontend evitando depender del portapapeles de Ubuntu VMware.
- Decisi?n t?cnica:
  - Usar Windows como entorno visual principal.
  - Conectar VS Code a Ubuntu VMware mediante Remote SSH.
  - Mantener el proyecto Flutter físicamente en Ubuntu VMware.
- Herramienta principal recomendada:
  - VS Code + Remote SSH.
- Herramientas de apoyo:
  - Windows PowerShell con SSH para comandos rápidos.
  - ChatGPT para guía paso a paso.
- Herramienta no prioritaria por ahora:
  - Cursor se evaluará más adelante, cuando el flujo base está estable.
- Problema que resuelve:
  - Permite editar archivos con resaltado de sintaxis, árbol de carpetas y terminal integrada sin depender del copiar/pegar entre VMware y Windows.
- Estado:
  - VS Code instalado en Windows.
  - Extensión Remote SSH instalada.
  - Pendiente abrir Ubuntu VMware desde VS Code y abrir la carpeta del frontend.

## B69 — Conexion inicial de la UI con ApiService

- Objetivo: conectar la pantalla principal del frontend con el backend FastAPI.
- Archivo modificado:
  - lib/main.dart
- Servicio utilizado:
  - lib/services/api_service.dart
- Cambio realizado:
  - Se importo ApiService en la pantalla principal.
  - Se uso FutureBuilder para ejecutar checkHealth().
  - Se agrego un mensaje visual para mostrar si el backend esta conectado o no disponible.
- Problema que resuelve:
  - Permite que la UI consulte por primera vez el estado real del backend sin mezclar logica HTTP directamente en la pantalla.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.


## B70 — Migración del backend a Ubuntu VMware

* Objetivo: migrar el backend desde WSL2 hacia Ubuntu VMware para unificar el entorno de desarrollo.
* Ruta anterior:

  * WSL2: ~/proyectos/app-ingles-backend
* Ruta nueva:

  * Ubuntu VMware: ~/projects/app_ingles_backend/app-ingles-backend
* Cambio realizado:

  * Se clono el repositorio backend desde GitHub en Ubuntu VMware.
  * Se creo un entorno virtual local .venv.
  * Se instalaron las dependencias desde requirements.txt.
  * Se instalo PostgreSQL en Ubuntu VMware.
  * Se creo la base de datos local app_ingles_db.
  * Se creo el usuario PostgreSQL appIngles.
  * Se creo el archivo .env local con DATABASE_URL.
  * Se ejecutó el script app.db.create_tables para crear la tabla user_progress.
* Problema que resuelve:

  * Elimina la dependencia de WSL2, Windows portproxy y comunicacion cruzada entre Windows y Ubuntu.
  * Permite trabajar backend, frontend, PostgreSQL, VS Code, Flutter y Git/GitHub desde Ubuntu VMware local.
* Validaciones realizadas:

  * pytest
  * uvicorn app.main:app
  * curl http://127.0.0.1:8000/api/v1/health
* Resultado:

  * 17 tests passed.
  * Backend levantado en http://0.0.0.0:8000.
  * Endpoint /api/v1/health respondio {"status":"ok"}.
* Decision tecnica:

  * Ubuntu VMware local queda como entorno principal del proyecto app-ingles.
  * WSL2 deja de ser el entorno principal para este proyecto.
## B70 — Actualización del frontend para backend local

* Objetivo: conectar el frontend Flutter con el backend migrado a Ubuntu VMware.
* Archivo modificado:

  * lib/services/api_service.dart
* Cambio realizado:

  * Se cambio la URL base del ApiService.
  * Antes apuntaba a http://192.168.1.33:8000/api/v1.
  * Ahora apunta a http://127.0.0.1:8000/api/v1.
* Problema que resuelve:

  * Elimina la dependencia de Windows, WSL2 y portproxy para conectar frontend y backend.
  * Permite que Flutter consuma el backend FastAPI ejecutado localmente en Ubuntu VMware.
* Validaciones realizadas:

  * flutter analyze
  * flutter test
* Resultado:

  * No issues found.
  * All tests passed.
* Decision tecnica:

  * Ubuntu VMware local queda como entorno principal para frontend y backend.

## B70 — Migración del backend a Ubuntu VMware

- Objetivo: migrar el backend desde WSL2 hacia Ubuntu VMware para unificar el entorno de desarrollo.
- Ruta nueva:
  - ~/projects/app_ingles_backend/app-ingles-backend
- Cambios realizados:
  - Se clonó el backend desde GitHub.
  - Se creó el entorno virtual .venv.
  - Se instalaron dependencias desde requirements.txt.
  - Se instaló PostgreSQL local en Ubuntu VMware.
  - Se creó la base de datos app_ingles_db.
  - Se creó el usuario PostgreSQL appIngles.
  - Se creó el archivo .env local con DATABASE_URL.
  - Se ejecutó app.db.create_tables para crear la tabla user_progress.
  - Se agregó .venv/ al .gitignore.
- Validaciones realizadas:
  - pytest: 17 tests passed.
  - Backend levantado con Uvicorn.
  - Endpoint /api/v1/health respondió {"status":"ok"}.
- Decisión técnica:
  - Ubuntu VMware local queda como entorno principal del proyecto.
  - WSL2 deja de ser el entorno principal para app-ingles.

## B71 — Verificación completa del sistema en Ubuntu
- Objetivo: validar que backend, frontend, PostgreSQL y Git funcionan correctamente desde Ubuntu VMware local.
- Validaciones realizadas:
  - Backend health:
    - curl http://127.0.0.1:8000/api/v1/health
  - Frontend:
    - flutter analyze
    - flutter test
  - Backend:
    - pytest
  - Git:
    - git status -sb en backend
    - git status -sb en frontend
- Resultado:
  - Backend respondio {"status":"ok"}.
  - Frontend sin errores de analisis.
  - Frontend tests passed.
  - Backend 17 tests passed.
  - Git limpio en backend y frontend.
- Decision tecnica:
  - Se confirma Ubuntu VMware local como entorno principal estable para app-ingles.
## B72 — Mostrar niveles desde el backend

- Objetivo: mostrar los niveles A1-C2 en la pantalla principal.
- Archivos modificados:
  - lib/services/api_service.dart
  - lib/main.dart
- Cambio realizado:
  - Se agrego getLevels() en ApiService.
  - Se conecto HomeScreen al endpoint /levels.
  - Se muestran los niveles usando chips en la interfaz.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B73 — Separación de HomeScreen

- Objetivo: separar la pantalla principal en su propio archivo.
- Archivos modificados:
  - lib/main.dart
  - lib/screens/home_screen.dart
- Cambio realizado:
  - Se creó la carpeta lib/screens.
  - Se movió HomeScreen desde main.dart hacia lib/screens/home_screen.dart.
  - main.dart quedó como punto de entrada principal de la app.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B74 — Modelo Level para niveles

- Objetivo: preparar una estructura escalable para representar niveles.
- Archivos modificados:
  - lib/models/level.dart
  - lib/services/api_service.dart
  - lib/screens/home_screen.dart
- Cambio realizado:
  - Se creó el modelo Level.
  - ApiService.getLevels() ahora devuelve List<Level>.
  - HomeScreen usa level.code para mostrar los niveles.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B75 — Mostrar unidades A1 desde el backend

- Objetivo: mostrar unidades del nivel A1 desde el backend.
- Archivos modificados:
  - lib/models/unit.dart
  - lib/services/api_service.dart
  - lib/screens/home_screen.dart
- Cambio realizado:
  - Se creó el modelo Unit.
  - Se agregó getUnits(String levelCode) en ApiService.
  - HomeScreen muestra unidades A1 usando Card y ListTile.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B76 — Selección dinámica de nivel

- Objetivo: permitir seleccionar un nivel y cargar sus unidades desde el backend.
- Archivo modificado:
  - lib/screens/home_screen.dart
- Cambio realizado:
  - HomeScreen pasó de StatelessWidget a StatefulWidget.
  - Se agregó selectedLevelCode con valor inicial A1.
  - Se reemplazaron chips simples por ChoiceChip.
  - Las unidades se cargan usando getUnits(selectedLevelCode).
  - Se agregó scroll con SingleChildScrollView.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B77 — Selección de unidad y carga de lecciones

- Objetivo: permitir seleccionar una unidad y mostrar sus lecciones desde el backend.
- Archivos modificados:
  - lib/models/lesson.dart
  - lib/services/api_service.dart
  - lib/screens/home_screen.dart
- Cambio realizado:
  - Se creó el modelo Lesson.
  - Se agregó getLessons(String unitId) en ApiService.
  - HomeScreen permite seleccionar una unidad.
  - Al seleccionar una unidad se muestran sus lecciones.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B78 — Selección de lección y detalle completo

- Objetivo: permitir seleccionar una lección y mostrar su detalle completo desde el backend.
- Archivos modificados:
  - lib/models/lesson.dart
  - lib/services/api_service.dart
  - lib/screens/home_screen.dart
- Cambio realizado:
  - Se amplió el modelo Lesson para soportar vocabulary, grammar, examples y exercises.
  - Se agregó getLesson(String lessonId) en ApiService.
  - HomeScreen permite seleccionar una lección.
  - Al seleccionar una lección se muestra su objetivo, vocabulario, gramática, ejemplos y ejercicios.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B79 — Mejora visual del detalle de lección

- Objetivo: mejorar la estructura visual del detalle de lección sin cambiar la lógica ni el backend.
- Archivo modificado:
  - lib/screens/home_screen.dart
- Cambio realizado:
  - Se reorganizó HomeScreen en métodos privados de construcción visual.
  - Se agregaron tarjetas para separar secciones.
  - Se controló el ancho máximo de la pantalla.
  - Se añadieron iconos básicos para unidades, lecciones y ejercicios.
  - Se separó el detalle de lección en objetivo, vocabulario, gramática, ejemplos y ejercicios.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B80 — Separación de widgets de HomeScreen

- Objetivo: reducir el tamaño de HomeScreen separando componentes visuales reutilizables.
- Archivos modificados:
  - lib/screens/home_screen.dart
  - lib/widgets/info_card.dart
- Cambio realizado:
  - Se creó InfoCard como tarjeta reutilizable.
  - Se creó LessonContentSection para secciones internas del detalle de lección.
  - HomeScreen ahora importa y usa estos widgets externos.
  - Se eliminó lógica visual duplicada dentro de HomeScreen.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B81 — Separación del detalle de lección en widget propio

- Objetivo: mover el detalle completo de la lección fuera de HomeScreen.
- Archivos modificados:
  - lib/screens/home_screen.dart
  - lib/widgets/lesson_detail_card.dart
- Cambio realizado:
  - Se creó LessonDetailCard como widget específico para mostrar el detalle de una lección.
  - HomeScreen ahora delega la visualización del detalle a LessonDetailCard.
  - HomeScreen queda más enfocado en coordinar nivel, unidad y lección.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.

## B82 — Separación de listas de unidades y lecciones

- Objetivo: mover las listas de unidades y lecciones fuera de HomeScreen.
- Archivos modificados:
  - lib/screens/home_screen.dart
  - lib/widgets/unit_list_card.dart
  - lib/widgets/lesson_list_card.dart
- Cambio realizado:
  - Se creó UnitListCard para mostrar unidades del nivel seleccionado.
  - Se creó LessonListCard para mostrar lecciones de la unidad seleccionada.
  - HomeScreen ahora coordina estado y delega la presentación de listas.
  - Se corrigieron constructores agregando const.
- Validaciones realizadas:
  - flutter analyze
  - flutter test
- Resultado:
  - No issues found.
  - All tests passed.
## B83 — Separar selector de niveles en widget propio

- Se creó `lib/widgets/level_selector_card.dart`.
- `HomeScreen` ahora delega el selector de niveles al widget `LevelSelectorCard`.
- Se mantiene la lógica de selección de nivel en `HomeScreen`.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B84 — Separar detalle de lección en pantalla propia

- Se creó `lib/screens/lesson_detail_screen.dart`.
- `LessonDetailScreen` carga y muestra el detalle completo de una lección.
- `HomeScreen` ahora navega hacia `LessonDetailScreen` al seleccionar una lección.
- Se eliminó de `HomeScreen` la carga directa del detalle de lección.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B85 — Preparar ejercicios interactivos

- Se creó `lib/widgets/lesson_exercise_card.dart`.
- `LessonExerciseCard` permite seleccionar una opción y comprobar si la respuesta es correcta.
- `LessonDetailCard` ahora muestra ejercicios mediante tarjetas interactivas.
- La validación de respuesta es local usando `answerIndex`.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B86 — Conectar ejercicios con backend

- Se agregó `submitExerciseAnswer()` en `lib/services/api_service.dart`.
- El método envía respuestas al endpoint `/exercises/{exercise_id}/submit`.
- `LessonExerciseCard` ahora valida respuestas usando el backend.
- Se mantiene estado de carga con el texto `Comprobando...`.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B87 — Registrar progreso del usuario

- Se verificó el contrato real del endpoint `/progress`.
- El backend requiere: `user_id`, `level_id`, `unit_id`, `lesson_id`, `exercise_id`, `selected_index` y `correct`.
- Se agregó `saveProgress()` en `lib/services/api_service.dart`.
- `LessonExerciseCard` ahora guarda progreso después de comprobar una respuesta.
- Se usa temporalmente `demo-user` hasta implementar autenticación.
- `LessonDetailCard`, `LessonDetailScreen` y `HomeScreen` pasan `levelId`, `unitId` y `lessonId`.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B88 — Leer progreso del usuario

- Se verificó que el backend devuelve progreso con `GET /progress/demo-user`.
- Se creó `lib/models/progress_record.dart`.
- Se agregó `getProgress()` en `lib/services/api_service.dart`.
- `ProgressRecord` representa los registros de progreso recibidos desde el backend.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B89 — Mostrar resumen básico de progreso

- Se creó `lib/widgets/progress_summary_card.dart`.
- `ProgressSummaryCard` lee el progreso de `demo-user` usando `getProgress()`.
- La pantalla principal ahora muestra una tarjeta `Progreso`.
- El resumen muestra ejercicios respondidos y respuestas correctas.
- `HomeScreen` fue actualizado para insertar `ProgressSummaryCard` entre el estado del backend y el selector de niveles.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B90 — Actualizar progreso al volver de una lección

- `HomeScreen` ahora espera el retorno desde `LessonDetailScreen`.
- Se agregó `_progressRefreshCounter` para forzar la reconstrucción de `ProgressSummaryCard`.
- La tarjeta de progreso se actualiza al volver desde una lección.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.


## B91 — Mostrar retroalimentación pedagógica después de responder

- Se agregó retroalimentación pedagógica local en `LessonExerciseCard`.
- Después de comprobar una respuesta, la app muestra un mensaje breve de orientación.
- Si la respuesta es incorrecta, se muestra la respuesta correcta para comparación.
- Este bloque inicia la transición desde ejercicios simples hacia una dinámica más pedagógica y conversacional.
- Validación ejecutada:
  - `flutter analyze` → No issues found.
  - `flutter test` → All tests passed.

