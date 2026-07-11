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
  - Se creó ApiService con baseUrl apuntando a <http://192.168.1.33:8000/api/v1>.
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

- Objetivo: migrar el backend desde WSL2 hacia Ubuntu VMware para unificar el entorno de desarrollo.
- Ruta anterior:

  - WSL2: ~/proyectos/app-ingles-backend
- Ruta nueva:

  - Ubuntu VMware: ~/projects/app_ingles_backend/app-ingles-backend
- Cambio realizado:

  - Se clono el repositorio backend desde GitHub en Ubuntu VMware.
  - Se creo un entorno virtual local .venv.
  - Se instalaron las dependencias desde requirements.txt.
  - Se instalo PostgreSQL en Ubuntu VMware.
  - Se creo la base de datos local app_ingles_db.
  - Se creo el usuario PostgreSQL appIngles.
  - Se creo el archivo .env local con DATABASE_URL.
  - Se ejecutó el script app.db.create_tables para crear la tabla user_progress.
- Problema que resuelve:

  - Elimina la dependencia de WSL2, Windows portproxy y comunicacion cruzada entre Windows y Ubuntu.
  - Permite trabajar backend, frontend, PostgreSQL, VS Code, Flutter y Git/GitHub desde Ubuntu VMware local.
- Validaciones realizadas:

  - pytest
  - uvicorn app.main:app
  - curl <http://127.0.0.1:8000/api/v1/health>
- Resultado:

  - 17 tests passed.
  - Backend levantado en <http://0.0.0.0:8000>.
  - Endpoint /api/v1/health respondio {"status":"ok"}.
- Decision tecnica:

  - Ubuntu VMware local queda como entorno principal del proyecto app-ingles.
  - WSL2 deja de ser el entorno principal para este proyecto.

## B70 — Actualización del frontend para backend local

- Objetivo: conectar el frontend Flutter con el backend migrado a Ubuntu VMware.
- Archivo modificado:

  - lib/services/api_service.dart
- Cambio realizado:

  - Se cambio la URL base del ApiService.
  - Antes apuntaba a <http://192.168.1.33:8000/api/v1>.
  - Ahora apunta a <http://127.0.0.1:8000/api/v1>.
- Problema que resuelve:

  - Elimina la dependencia de Windows, WSL2 y portproxy para conectar frontend y backend.
  - Permite que Flutter consuma el backend FastAPI ejecutado localmente en Ubuntu VMware.
- Validaciones realizadas:

  - flutter analyze
  - flutter test
- Resultado:

  - No issues found.
  - All tests passed.
- Decision tecnica:

  - Ubuntu VMware local queda como entorno principal para frontend y backend.

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
    - curl <http://127.0.0.1:8000/api/v1/health>
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

## B92 — Adoptar sistema profesional de ingeniería

- Se creó `docs/engineering-system-v2.md`.
- Se definió un método de desarrollo basado en capacidades verticales y valor para el usuario.
- Se incorporaron criterios de aceptación y una Definition of Done profesional.
- Se establecieron estrategias progresivas de pruebas, arquitectura evolutiva, revisión de código, CI y DevSecOps.
- Se priorizó conversación fluida, comprensión auditiva, práctica oral y retroalimentación pedagógica.
- Se fijó como objetivo una versión innovadora en tres meses mediante alcance controlado y entregas frecuentes.
- Validación documental:
  - `git diff --check` → Sin errores.

## B93 — Primera capacidad vertical conversacional: escuchar una frase

- Se incorporó `audioplayers 6.7.1` para reproducir recursos de audio locales.
- Se registró `assets/audio/` en `pubspec.yaml`.
- Se generaron dos audios WAV provisionales para `Hello, I am John.`:
  - `en-US`: `assets/audio/a1_u1_l1_hello_us.wav`;
  - `en-GB`: `assets/audio/a1_u1_l1_hello_uk.wav`.
- Los audios utilizan temporalmente voces masculinas de eSpeak NG:
  - `en-us` para inglés estadounidense;
  - `en-gb` para inglés británico;
  - velocidad `145`.
- eSpeak NG queda limitado a prototipo local y respaldo offline.
- Azure AI Speech se evaluará posteriormente para voces neuronales y evaluación de pronunciación.
- Se añadió al contrato del backend la estructura escalable `pronunciations`.
- Cada pronunciación contiene:
  - `locale`;
  - transcripción `ipa`;
  - `audio_asset`.
- Las variantes actuales son:
  - `en-US` — inglés estadounidense;
  - `en-GB` — inglés británico.
- Se creó el modelo Flutter `LessonPronunciation`.
- `LessonExample` ahora admite una lista de pronunciaciones regionales.
- Se creó `LessonPronunciationControls` para mostrar:
  - nombre de la variante;
  - transcripción IPA;
  - botón y estado de reproducción;
  - mensaje de error.
- `LessonDetailCard` integra los controles debajo de cada frase de ejemplo.
- `ApiService` utiliza `http://127.0.0.1:8001/api/v1`.
- Decisión de entorno local:
  - CNAPP-Lite conserva el puerto `8000`;
  - App Inglés utiliza el puerto `8001`;
  - los entornos virtuales aíslan dependencias, pero no puertos.
- Se completó la cadena de compilación Flutter Linux y el soporte GStreamer requerido por `audioplayers_linux`.
- Validación manual en Linux Desktop:
  - la aplicación compiló y abrió correctamente;
  - se mostraron las variantes `en-US` y `en-GB`;
  - ambas mostraron su IPA;
  - ambos audios se reprodujeron sin errores.
- Decisión de alcance:
  - B93 se cierra por funcionamiento de la capacidad;
  - el pulido visual o `UI polish` queda para un bloque posterior.
- Validaciones finales:
  - `flutter analyze` → No issues found;
  - `flutter test` → All tests passed;
  - `pytest -q` en backend → 17 pruebas superadas en 0.64 segundos;
  - `git diff --check` en frontend y backend → sin errores;
  - prueba visual y auditiva en Linux Desktop → correcta.
- Resultado:
  - la primera capacidad vertical de escucha quedó implementada y validada;
  - la voz neuronal y el pulido visual quedan para bloques posteriores.

## B94 — Escuchar, grabar y comparar pronunciación

### Capacidad vertical

El estudiante podrá escuchar una pronunciación de referencia, grabar su propia repetición y comparar ambos audios desde la misma lección.

La grabación será local y temporal. No se enviará al backend ni recibirá evaluación automática en este bloque.

### Criterios de aceptación

1. Los controles de pronunciación de B93 continúan funcionando para `en-US` y `en-GB`.
2. La interfaz permite iniciar una grabación desde el ejemplo activo.
3. Durante la grabación se muestra claramente el estado `Grabando...`.
4. El usuario puede detener la grabación manualmente.
5. Después de detenerla, puede reproducir su propia voz.
6. Puede volver a grabar y reemplazar la grabación anterior.
7. Puede eliminar la grabación temporal.
8. El audio de referencia y la grabación del usuario no pueden reproducirse simultáneamente.
9. Los errores de permisos, micrófono o reproducción se muestran de forma comprensible y no bloquean la lección.
10. La grabación no se guarda en el backend ni persiste al cerrar la pantalla.
11. La lógica de grabación y reproducción queda separada del widget visual cuando sea necesario para mantener el código testeable.
12. Las pruebas cubren los estados principales: inicial, grabando, grabación disponible, reproducción y error.
13. `flutter analyze` finaliza sin incidencias.
14. `flutter test` finaliza correctamente.
15. Se realizan las revisiones de seguridad y código exigidas por Engineering System v2.
16. La capacidad y sus decisiones quedan documentadas antes de cerrar B94.
17. El bloque termina con commit, push y Git limpio y sincronizado.

### Fuera del alcance de B94 — previsto para bloques posteriores

- Reconocimiento automático de palabras.
- Puntuación de pronunciación.
- Comparación fonética con IPA.
- Envío o almacenamiento de audio en el backend.
- Historial de grabaciones.
- Conversaciones completas con IA.

### Implementación realizada

- Se añadió `record 6.2.1` para la captura local de audio.
- Se declaró `path_provider 2.1.6` como dependencia directa para administrar archivos temporales.
- En Ubuntu se instalaron:
  - `pulseaudio-utils`, que proporciona `parecord` y `pactl`;
  - `ffmpeg`, utilizado por `record_linux`.
- Se confirmó que `record_linux 1.3.1` admite:
  - `AudioEncoder.wav`;
  - codificación PCM de 16 bits `pcm_s16le`;
  - grabación mono mediante `numChannels: 1`.
- Se creó `PronunciationAudioController` como contrato testeable para las operaciones de audio.
- Se creó `PronunciationAudioService` para coordinar:
  - reproducción de audios de referencia;
  - grabación WAV temporal;
  - reproducción de la voz del estudiante;
  - exclusión entre reproducción y grabación;
  - eliminación manual de grabaciones;
  - limpieza automática al cerrar la lección.
- El servicio publica los identificadores de reproducción y grabación activos para sincronizar todos los ejemplos de una lección.
- `LessonDetailScreen` se convirtió en `StatefulWidget`.
- La pantalla crea un único `PronunciationAudioService` por lección y lo libera mediante `dispose()`.
- `LessonDetailCard` comparte el servicio con todos los ejemplos.
- Cada ejemplo utiliza un identificador local con el formato:
  - `<lessonId>:example:<índice>`.
- `LessonPronunciationControls` permite:
  - escuchar las variantes `en-US` y `en-GB`;
  - iniciar una grabación;
  - mostrar el estado `Grabando...`;
  - detener la grabación;
  - reproducir la voz del estudiante;
  - volver a grabar;
  - eliminar la grabación temporal.
- Una nueva grabación reemplaza el archivo temporal anterior del mismo ejemplo.
- Los audios de referencia, la voz del estudiante y el micrófono no pueden utilizarse simultáneamente.
- Los errores de permiso, micrófono, reproducción y eliminación se muestran sin bloquear la lección.
- Las grabaciones no se envían al backend.
- Los archivos WAV se conservan únicamente mientras la pantalla de la lección permanece abierta.
- Al salir de la lección, los archivos `pronunciation_*.wav` se eliminan automáticamente.
- Los archivos de registro de plugins de Linux, macOS y Windows fueron actualizados automáticamente por Flutter.

### Pruebas automatizadas

- Se creó `test/lesson_pronunciation_controls_test.dart`.
- Se añadió `FakePronunciationAudioController` para probar la interfaz sin utilizar plugins nativos.
- Las pruebas cubren:
  - estado inicial;
  - estado de grabación;
  - grabación disponible;
  - reproducción de la voz;
  - permiso de micrófono denegado;
  - regrabación y eliminación de la voz.
- Resultado de las pruebas específicas:
  - `flutter test test/lesson_pronunciation_controls_test.dart` → 6 pruebas superadas.
- Resultado de la suite completa:
  - `flutter test` → 7 pruebas superadas.
- Resultado del análisis completo:
  - `flutter analyze` → `No issues found`.
- Integridad del diff:
  - `git diff --check` → sin salida y sin errores.

### Validación funcional en Linux Desktop

- El backend respondió correctamente en:
  - `http://127.0.0.1:8001/api/v1/health`.
- La aplicación compiló y abrió correctamente con `flutter run -d linux`.
- Se verificó visualmente la presencia de:
  - `Practica tu pronunciación`;
  - `Grabar mi voz`.
- Se validó el acceso real al micrófono.
- Se validaron los estados:
  - `Grabando...`;
  - `Detener grabación`;
  - `Grabación disponible`;
  - `Reproducir mi voz`;
  - `Volver a grabar`;
  - `Eliminar`.
- La voz grabada se reprodujo correctamente.
- La segunda grabación reemplazó a la primera.
- La eliminación manual devolvió la interfaz al estado inicial.
- Los audios de referencia `en-US` y `en-GB` continuaron funcionando.
- Se comprobó la creación real de un archivo WAV en `/tmp`.
- Se comprobó que el WAV desaparece automáticamente al salir de la lección.

### Revisión de seguridad

- No se almacena voz en el backend.
- No se transmite audio por red.
- La grabación requiere permiso del micrófono.
- Durante la revisión se detectó que el primer WAV directo en `/tmp` tenía permisos `664`, por lo que esa implementación fue descartada.
- También se detectó que el primer subdirectorio temporal privado se creaba inicialmente con permisos `775`.
- La implementación final crea un subdirectorio exclusivo con permisos `700`.
- Cada archivo WAV se restringe a permisos `600`.
- Se verificaron los permisos reales:
  - directorio: `700 drwx------`;
  - archivo: `600 -rw-------`.
- El usuario puede eliminar manualmente su grabación.
- Al salir de la lección se eliminan automáticamente:
  - los archivos WAV restantes;
  - el subdirectorio temporal privado.
- Se verificó que no quedan rutas `/tmp/app_ingles_pronunciation_*` después de cerrar la pantalla.
- `path_provider` fue retirado como dependencia directa porque dejó de utilizarse.
- La persistencia y el historial de voz permanecen fuera del alcance de B94 y requerirán consentimiento, retención y controles de privacidad.

### Cierre técnico previo a Git

- Revisión completa del código realizada.
- Revisión de seguridad completada.
- `flutter analyze` → `No issues found`.
- `flutter test` → 7 pruebas superadas.
- `git diff --check` → sin salida y sin errores.
- Dependencias revisadas:
  - `record: ^6.2.1` permanece como dependencia directa;
  - `path_provider` fue retirado como dependencia directa.

### Pendiente para cerrar B94

- Realizar commit y push.
- Confirmar Git limpio y sincronizado.
