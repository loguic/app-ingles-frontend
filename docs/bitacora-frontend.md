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

### Cierre de B94

- Commit: `9705ba4`.
- Mensaje: `B94 añadir grabación y comparación de pronunciación`.
- Push realizado a `origin/master`.
- Git quedó limpio y sincronizado.

## B95 — Repetición guiada de una frase

### Capacidad vertical

El estudiante puede practicar una frase mediante un recorrido guiado:

`Escuchar → Grabar → Escuchar mi voz → Repetir práctica`

La capacidad reutiliza la reproducción y grabación local desarrolladas en B93 y B94, pero organiza las acciones mediante pasos pedagógicos visibles.

### Implementación realizada

- Se añadió el estado interno `_GuidedPracticeStep` con las etapas:
  - `listen`;
  - `record`;
  - `review`;
  - `repeat`.
- La primera pronunciación disponible queda seleccionada inicialmente.
- El estudiante puede seleccionar entre las variantes `en-US` y `en-GB`.
- La interfaz muestra:
  - la variante activa;
  - el paso actual;
  - la instrucción pedagógica correspondiente.
- Cuando termina realmente el audio de referencia, la guía avanza al paso de grabación.
- Cuando se crea correctamente el WAV, la guía avanza al paso de revisión.
- Cuando termina la reproducción de la voz del estudiante, la práctica queda completada.
- Se añadió el botón `Repetir práctica`.
- Al reiniciar:
  - se conserva la variante seleccionada;
  - se libera primero la fuente del reproductor;
  - se elimina la grabación anterior;
  - la guía vuelve al paso inicial.
- Al cambiar de variante se elimina cualquier grabación asociada a la variante anterior.
- Se añadió protección para ejemplos sin pronunciaciones, evitando acceder a una lista vacía.
- No se añadieron dependencias.
- No se modificó el backend.

### Pruebas

- Se amplió `FakePronunciationAudioController` con `completePlayback()` para simular la finalización natural de un audio.
- Se añadió una prueba del recorrido completo:
  - escuchar referencia;
  - avanzar a grabación;
  - detener grabación;
  - reproducir la voz;
  - completar la práctica;
  - reiniciar el recorrido.
- Resultado final:
  - `flutter test` → 8 pruebas superadas.

### Validación manual

- La práctica guiada completa funcionó en Linux Desktop.
- El cambio entre `en-US` y `en-GB` funcionó correctamente.
- Al cambiar de variante se reinició la guía y desapareció la grabación anterior.
- El botón `Repetir práctica` apareció después de completar el recorrido.
- El reinicio eliminó el WAV anterior y permitió volver a reproducir el audio de referencia.
- Fue necesario reiniciar completamente la aplicación durante una validación porque una sesión anterior conservaba el estado nativo del reproductor.

### Revisión de código y seguridad

- Se revisó el diff completo del widget y sus pruebas.
- Se eliminaron bloques y comentarios duplicados detectados durante el desarrollo.
- Se protegió el acceso cuando `pronunciations` está vacío.
- El audio continúa siendo local y temporal.
- No se almacena ni transmite voz al backend.
- La grabación anterior se elimina al cambiar de variante o reiniciar la práctica.
- El reproductor se detiene antes de eliminar el WAV utilizado como fuente.
- No se modificaron los permisos seguros ni la limpieza temporal implementados en B94.

### Validaciones técnicas

- `dart format` aplicado.
- `flutter analyze` → `No issues found`.
- `flutter test` → 8 pruebas superadas.
- `git diff --check` → sin salida ni errores.

### Cierre de B95

- Commit: `c5be81d`.
- Mensaje: `B95 añadir repetición guiada de pronunciación`.
- Push realizado a `origin/master`.
- Git quedó limpio y sincronizado en `master...origin/master`.

## B96 — Autoevaluación guiada de pronunciación

### Capacidad vertical

Después de escuchar su propia grabación, el estudiante puede reflexionar subjetivamente sobre su pronunciación mediante el recorrido:

`Escuchar referencia → Grabar → Escuchar mi voz → Autoevaluarme → Retroalimentación pedagógica → Repetir práctica`

La capacidad no realiza reconocimiento automático ni asigna una puntuación. La orientación se basa únicamente en la percepción seleccionada por el estudiante.

### Implementación realizada

- Se amplió `_GuidedPracticeStep` con la etapa `selfAssess`.
- El recorrido guiado ahora contiene:
  - `listen`;
  - `record`;
  - `review`;
  - `selfAssess`;
  - `repeat`.
- Al terminar la reproducción de la voz del estudiante, la guía avanza a la autoevaluación.
- Se añadió `_PronunciationSelfAssessment` con las opciones:
  - `good`;
  - `almost`;
  - `repeat`.
- La interfaz muestra:
  - `Me salió bien`;
  - `Casi, necesito practicar`;
  - `Quiero repetir`.
- La elección se guarda temporalmente en `_selfAssessment`.
- Se muestra una orientación pedagógica breve según la opción seleccionada.
- Después de elegir una opción, la guía avanza al estado `repeat`.
- La grabación y el audio de referencia continúan disponibles durante la autoevaluación.
- La autoevaluación anterior se limpia al:
  - cambiar de variante;
  - reiniciar la práctica;
  - iniciar una nueva grabación.
- No se añadieron dependencias.
- No se modificó el backend.
- No se añadió persistencia de la autoevaluación.

### Pruebas

- Se actualizó la prueba automatizada del recorrido completo.
- La prueba verifica:
  - reproducción de la referencia;
  - avance a grabación;
  - creación de una grabación válida;
  - reproducción de la voz del estudiante;
  - aparición del Paso 4;
  - presencia de las tres opciones de autoevaluación;
  - selección de `Casi, necesito practicar`;
  - aparición de la orientación pedagógica correspondiente;
  - aparición del botón `Repetir práctica`;
  - limpieza de la grabación y de la autoevaluación al reiniciar.
- Resultado final:
  - `flutter test` → 8 pruebas superadas.

### Validación manual

- El recorrido completo funcionó correctamente en Linux Desktop.
- Después de escuchar la voz apareció el Paso 4.
- Las tres opciones de autoevaluación se mostraron correctamente.
- Al elegir una opción:
  - desaparecieron las opciones;
  - apareció la orientación pedagógica;
  - apareció el botón `Repetir práctica`.
- El audio de referencia y la grabación continuaron disponibles.
- Al reiniciar:
  - la guía volvió al Paso 1;
  - desapareció la orientación anterior;
  - se eliminó la grabación temporal anterior.
- Al cambiar entre `en-US` y `en-GB`, no permaneció la autoevaluación anterior.

### Revisión de código y seguridad

- Se revisó el diff completo del widget y de su prueba.
- La autoevaluación se mantiene únicamente en memoria local.
- No se transmite la elección al backend.
- No se transmite ni almacena la voz fuera del flujo temporal existente.
- No se añadió reconocimiento automático, puntuación fonética ni inteligencia artificial.
- No se modificó la gestión segura del archivo WAV temporal.
- No se añadieron dependencias ni cambios fuera del alcance de B96.

### Validaciones técnicas

- `dart format` aplicado.
- `flutter analyze` → `No issues found`.
- Prueba específica de pronunciación → 7 pruebas superadas.
- Suite completa `flutter test` → 8 pruebas superadas.
- `git diff --check` → sin salida ni errores.

### Cierre de B96

- Commit funcional: `848ea72`.
- Mensaje funcional: `B96 añadir autoevaluación guiada de pronunciación`.
- Commit documental: `01574d8`.
- Mensaje documental: `docs cerrar B96 en bitácora`.
- Push realizado a `origin/master`.
- Git quedó limpio y sincronizado en `master...origin/master`.

## B97 — Resumen local de finalización de una lección

### Capacidad vertical

El estudiante puede visualizar el avance de los ejercicios de la lección actual mediante el recorrido:

`Responder ejercicios → Ver avance → Completar todos → Consultar resultado global → Recibir orientación pedagógica`

La finalización representa únicamente la sesión actual. B97 no afirma que la lección quede completada permanentemente en el backend.

### Implementación realizada

- `LessonDetailCard` pasó de `StatelessWidget` a `StatefulWidget`.
- Se añadió `_exerciseResults`, un mapa local que guarda el último resultado de cada ejercicio mediante su `exercise.id`.
- Se calculan:
  - ejercicios totales;
  - ejercicios completados;
  - respuestas correctas;
  - estado de finalización de la lección.
- La interfaz muestra inicialmente:
  - `Ejercicios completados: X de Y`.
- Cuando todos los ejercicios han sido comprobados, muestra:
  - `Lección completada`;
  - `Respuestas correctas: X de Y`;
  - una orientación pedagógica según el resultado.
- Una nueva comprobación del mismo ejercicio actualiza su resultado sin aumentar el número de ejercicios completados.
- `LessonExerciseCard` incorpora el callback opcional `onResultChanged`.
- El callback solo se ejecuta cuando el backend devuelve un resultado válido.
- Se añadió inyección opcional de `ApiService` para realizar pruebas sin utilizar el backend real.
- `LessonDetailCard` acepta el contrato `PronunciationAudioController`, permitiendo probarlo sin activar complementos nativos.
- No se añadieron dependencias.
- No se modificó el backend.

### Pruebas

- Se creó `test/lesson_detail_card_test.dart`.
- La prueba utiliza:
  - `FakeApiService`;
  - `FakePronunciationAudioController`;
  - una lección local con dos ejercicios.
- La prueba verifica:
  - estado inicial `0 de 2`;
  - avance a `1 de 2`;
  - finalización en `2 de 2`;
  - resultado inicial de `1 de 2` respuestas correctas;
  - orientación para ejercicios que necesitan revisión;
  - nueva comprobación del segundo ejercicio;
  - actualización a `2 de 2` respuestas correctas;
  - orientación de resultado perfecto;
  - ausencia de conteo duplicado.
- Los recursos falsos de audio se liberan mediante `addTearDown`.
- Resultado final:
  - prueba específica B97 → 1 prueba superada;
  - suite completa → 9 pruebas superadas.

### Validación manual

- El recorrido funcionó correctamente en Linux Desktop.
- El resumen comenzó en `0 de N`.
- Cada ejercicio comprobado actualizó el avance.
- Al responder todos los ejercicios apareció `Lección completada`.
- Se mostraron las respuestas correctas respecto al total.
- La orientación pedagógica cambió según los resultados.
- Al volver a comprobar un ejercicio:
  - no aumentó el número de ejercicios completados;
  - se actualizó el número de respuestas correctas;
  - se mantuvo la retroalimentación individual.
- Al salir y volver a entrar, el resumen comenzó nuevamente en `0 de N`, según el alcance local aprobado.

### Revisión de código y seguridad

- Se revisaron los cambios completos de:
  - `lesson_detail_card.dart`;
  - `lesson_exercise_card.dart`;
  - `lesson_detail_card_test.dart`.
- El progreso global de B97 permanece únicamente en memoria durante la sesión.
- No se añadió una finalización persistente ficticia.
- Los resultados individuales continúan guardándose mediante el backend existente.
- La prueba no realiza solicitudes reales al backend.
- La prueba no activa plugins nativos de audio.
- No se modificó la gestión temporal de grabaciones.
- No se añadieron dependencias ni cambios fuera del alcance de B97.

### Validaciones técnicas

- `dart format` aplicado.
- Prueba específica B97 → 1 prueba superada.
- Suite completa `flutter test` → 9 pruebas superadas.
- `flutter analyze` → `No issues found`.
- `git diff --check` → sin salida ni errores.

### Cierre de B97

- Commit funcional: `ce3093c`.
- Mensaje funcional: `B97 añadir resumen local de finalización de lección`.
- Commit documental: `bca1dce`.
- Mensaje documental: `docs cerrar B97 en bitácora`.
- Push realizado a `origin/master`.
- Git quedó limpio y sincronizado en `master...origin/master`.

## B98 — Indicador persistente de avance por lección

### Capacidad vertical

El estudiante puede visualizar en la lista de lecciones el avance persistido de los ejercicios mediante el recorrido:

`Responder ejercicios → Regresar al inicio → Recuperar progreso guardado → Ver avance por lección`

B98 representa ejercicios respondidos al menos una vez. No afirma que la lección esté aprobada ni identifica el resultado más reciente de cada ejercicio.

### Contrato confirmado del backend

- El backend guarda cada respuesta como un nuevo registro de `UserProgress`.
- No existe una restricción única por usuario y ejercicio.
- Responder nuevamente el mismo ejercicio crea otro intento.
- El contrato de progreso disponible en el frontend no incluye `id` ni `created_at`.
- Por tanto, el frontend no puede identificar con seguridad cuál fue el último intento.
- B98 calcula únicamente ejercicios respondidos únicos mediante `exercise_id`.

### Implementación realizada

- `LessonListCard` acepta opcionalmente:
  - `ApiService`;
  - `userId`, con valor predeterminado `demo-user`.
- Se añadió carga conjunta de:
  - lecciones de la unidad;
  - registros persistidos de progreso.
- Para cada lección:
  - se obtienen sus identificadores de ejercicios;
  - se filtran los registros correspondientes a su `lessonId`;
  - se ignoran ejercicios que no pertenecen a la lección;
  - los intentos repetidos se deduplican mediante `exerciseId`.
- Se muestran únicamente los estados aprobados:
  - `Sin actividad`;
  - `En progreso: X de Y ejercicios`;
  - `Todos los ejercicios respondidos`.
- No se muestra:
  - lección aprobada;
  - finalización permanente;
  - resultado final correcto.
- `HomeScreen` añade una `ValueKey` a `LessonListCard`.
- La clave incorpora `_progressRefreshCounter`, permitiendo recargar el avance al regresar desde una lección.
- No se modificó el backend.
- No se añadieron dependencias.

### Pruebas

- Se creó `test/lesson_list_card_test.dart`.
- La prueba utiliza un `FakeApiService`.
- No realiza solicitudes al backend real.
- Se prueban tres lecciones:
  - sin actividad;
  - con progreso parcial;
  - con todos los ejercicios respondidos.
- La prueba verifica:
  - `Sin actividad`;
  - `En progreso: 1 de 2 ejercicios`;
  - `Todos los ejercicios respondidos`;
  - deduplicación de intentos repetidos;
  - exclusión de registros cuyo ejercicio no pertenece a la lección.
- La primera ejecución falló porque `find.text()` buscaba el estado como texto independiente.
- El estado forma parte del subtítulo junto con el objetivo de la lección.
- La prueba se corrigió usando `find.textContaining()` sin modificar la lógica funcional.

### Validación manual

- El backend respondió correctamente en `http://127.0.0.1:8001/api/v1/health`.
- La aplicación se ejecutó correctamente en Linux Desktop.
- La lista mostró un indicador persistente con valores numéricos reales.
- El avance se actualizó al regresar desde una lección.
- Volver a responder el mismo ejercicio no incrementó incorrectamente el conteo.
- No se mostró ninguna afirmación de aprobación o finalización permanente.
- Flutter se cerró correctamente después de la validación.

### Revisión de código y seguridad

- Se revisó el diff completo de:
  - `home_screen.dart`;
  - `lesson_list_card.dart`;
  - `lesson_list_card_test.dart`.
- `HomeScreen` solo incorpora la clave necesaria para refrescar la lista.
- El cálculo usa conjuntos de identificadores y no modifica los registros recibidos.
- Los intentos repetidos no aumentan el número de ejercicios respondidos.
- Los registros de otros ejercicios no contaminan el progreso de la lección.
- No se exponen datos adicionales del usuario.
- No se añadieron escrituras nuevas en el backend.
- No se añadieron dependencias ni cambios fuera del alcance de B98.

### Validaciones técnicas

- `dart format` aplicado.
- Prueba específica B98 → 1 prueba superada.
- Suite completa `flutter test` → 10 pruebas superadas.
- `flutter analyze` → `No issues found`.
- `git diff --check` → sin salida ni errores.

### Cierre de B98

- Commit funcional: `329881d`.
- Mensaje funcional: `B98 añadir avance persistente por lección`.
- Commit documental, push y confirmación de Git limpio pendientes.

## B99 — Práctica conversacional guiada

Estado: implementación y validación manual completadas; pendiente cierre Git/GitHub.

### Objetivo

Incorporar una primera práctica conversacional guiada y escalable que permita escuchar al interlocutor, comprender su intervención, responder oralmente y revisar la propia grabación antes de avanzar.

### Cambios realizados

- Se añadieron los modelos `ConversationTurn` y `Conversation`.
- `Lesson` admite ahora una colección opcional de conversaciones.
- Se mantuvo compatibilidad con lecciones que no contienen conversaciones.
- Se reutilizó `LessonPronunciation` para las variantes `en-US` y `en-GB`.
- Se creó `LessonConversationCard`.
- Se integró la conversación en `LessonDetailCard` reutilizando el controlador de audio compartido.
- Se implementó el recorrido: escuchar al interlocutor, comprender el turno, responder como estudiante, grabar, escuchar la propia voz, avanzar y repetir la conversación.
- La escucha de la propia grabación es obligatoria antes de avanzar.
- Los archivos WAV temporales se eliminan al cambiar de turno.
- No se añadieron IA, reconocimiento de voz, puntuación automática ni persistencia nueva.
- Se añadieron cuatro audios provisionales generados con eSpeak NG para los turnos del interlocutor en variantes estadounidense y británica.
- Se actualizó la identidad visual base a `LOGUIC English`, con paleta índigo y el eslogan `Escucha. Habla. Lee. Avanza.`

### Pruebas automatizadas

- `lesson_conversation_model_test.dart`: deserialización y compatibilidad sin conversaciones.
- `lesson_conversation_card_test.dart`: variantes regionales, escucha, comprensión, grabación, reproducción, bloqueo de avance, finalización y reinicio.
- `flutter analyze`: sin incidencias.
- Suite completa: `13 tests passed`.
- `git diff --check`: sin errores.

### Validación manual

- Aplicación Linux ejecutada con el backend disponible en `http://127.0.0.1:8001/api/v1`.
- Identidad visual de LOGUIC English mostrada correctamente.
- Primer turno validado con `en-US`.
- Primer turno validado con `en-GB`.
- Conversación completa validada.
- Grabación y reproducción de la voz del estudiante correctas.
- Avance condicionado a escuchar la grabación confirmado.
- Finalización y repetición de la conversación correctas.
- Sin problemas visuales ni auditivos detectados.

### Archivos principales

- `lib/models/lesson.dart`
- `lib/widgets/lesson_conversation_card.dart`
- `lib/widgets/lesson_detail_card.dart`
- `test/lesson_conversation_model_test.dart`
- `test/lesson_conversation_card_test.dart`
- `assets/audio/a1_u1_l1_c1_t1_us.wav`
- `assets/audio/a1_u1_l1_c1_t1_uk.wav`
- `assets/audio/a1_u1_l1_c1_t3_us.wav`
- `assets/audio/a1_u1_l1_c1_t3_uk.wav`
