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

## B100 — Práctica conversacional ramificada

Estado: implementación, validación automatizada y validación manual completadas; pendiente cierre Git/GitHub.

### Objetivo

Ampliar la práctica conversacional para permitir respuestas alternativas y recorridos ramificados, conservando la compatibilidad con las conversaciones guiadas de B99 y evitando mezclar la navegación del grafo con la gestión de audio y presentación.

### Contrato conversacional

- Se añadió `ConversationChoice` con:
  - identificador estable;
  - texto en inglés;
  - traducción opcional;
  - pronunciaciones regionales opcionales;
  - `nextTurnId` opcional.
- `ConversationTurn` admite ahora:
  - `nextTurnId`;
  - una lista opcional de `choices`.
- `Conversation` admite:
  - `startTurnId`;
  - resolución de turnos mediante `turnById`;
  - resolución del turno inicial mediante `initialTurn`.
- Las conversaciones guiadas antiguas siguen iniciándose en el primer turno y mantienen el avance lineal.

### Controlador de navegación

- Se creó `ConversationFlowController`.
- El controlador mantiene:
  - turno actual;
  - respuesta seleccionada;
  - historial de turnos recorridos;
  - estado de finalización.
- La navegación admite:
  - avance lineal para `guided`;
  - transición mediante `nextTurnId`;
  - selección obligatoria en turnos con alternativas;
  - seguimiento del destino asociado a la respuesta elegida;
  - finalización de rutas;
  - reinicio desde `startTurnId`.
- La navegación del grafo queda separada del audio y de la interfaz Flutter.

### Integración visual

- `LessonConversationCard` utiliza el controlador para avanzar y reiniciar.
- Los turnos ramificados muestran respuestas alternativas mediante `ChoiceChip`.
- El estudiante debe seleccionar una respuesta antes de grabar.
- El texto y la traducción mostrados corresponden a la opción elegida.
- El flujo conserva:
  - grabación;
  - reproducción de la propia voz;
  - obligación de escuchar la grabación;
  - avance posterior;
  - limpieza del archivo temporal.
- Solo se recorre la rama elegida.
- El reinicio limpia la selección anterior y vuelve al turno inicial declarado.
- Las conversaciones guiadas mantienen su comportamiento de B99.
- La sección se renombró como `Práctica conversacional`.
- Las rutas ramificadas muestran el número de turnos recorridos sin compararlo con los turnos de ramas no elegidas.
- El mensaje final distingue entre conversación guiada y ruta ramificada.

### Pruebas automatizadas

- `lesson_conversation_model_test.dart` valida:
  - conversaciones guiadas;
  - conversaciones ramificadas;
  - `startTurnId`;
  - `nextTurnId`;
  - respuestas alternativas;
  - compatibilidad con lecciones antiguas.
- `conversation_flow_controller_test.dart` valida:
  - inicio;
  - avance guiado;
  - finalización;
  - reinicio;
  - selección obligatoria;
  - seguimiento exclusivo de la rama elegida.
- `lesson_conversation_card_test.dart` valida:
  - recorrido guiado completo;
  - selección visual de respuesta;
  - grabación y revisión;
  - reacción correspondiente a la rama elegida;
  - exclusión de la rama no seleccionada;
  - finalización;
  - reinicio desde el turno inicial.

### Validaciones técnicas

- `flutter analyze` → `No issues found`.
- Suite completa `flutter test` → 18 pruebas superadas.
- `git diff --check` → sin salida ni errores.
- Commit de base estable:
  - `da223f6`;
  - `B100 añadir contrato y controlador conversacional`.

### Validación manual

- El backend respondió correctamente en el puerto 8001.
- La conversación guiada de B99 se completó y reinició correctamente.
- Se validaron correctamente las dos rutas ramificadas.
- Cada respuesta condujo únicamente a la reacción correspondiente.
- La reproducción de la voz siguió siendo obligatoria antes de avanzar.
- La finalización mostró el mensaje específico de la ruta elegida.
- El reinicio volvió al turno inicial y limpió la selección anterior.
- No se detectaron errores visuales ni excepciones en la terminal.

### Archivos principales

- `lib/models/lesson.dart`
- `lib/controllers/conversation_flow_controller.dart`
- `lib/widgets/lesson_conversation_card.dart`
- `lib/widgets/lesson_detail_card.dart`
- `test/lesson_conversation_model_test.dart`
- `test/conversation_flow_controller_test.dart`
- `test/lesson_conversation_card_test.dart`

### Cierre de B100

- Commit base: `da223f6` — `B100 añadir contrato y controlador conversacional`.
- Commit de integración: `fa94705`.
- Push completado a `origin/master`.
- Repositorio confirmado limpio al cerrar B100.

## B101 — Persistencia del progreso conversacional

Fecha: 2026-07-21

### Objetivo

- Persistir cada conversación completada como un intento independiente del progreso de ejercicios.
- No almacenar grabaciones ni archivos de audio.
- Permitir que la conversación finalice localmente aunque falle la red.

### Implementación frontend

- `ConversationFlowController` conserva los turnos recorridos y las opciones elegidas.
- `ApiService.saveConversationAttempt(...)` envía el intento a `POST /api/v1/conversation-attempts`.
- `LessonConversationCard` recibe usuario, nivel, unidad y lección.
- El guardado se ejecuta automáticamente al completar la conversación.
- Las reconstrucciones de la interfaz no generan guardados duplicados.
- Repetir y completar nuevamente crea un intento independiente.
- El estado final informa si el intento se guardó o si falló la persistencia.
- Un fallo de red no bloquea la finalización ni el reinicio local.

### Pruebas automatizadas

- Historial y limpieza de opciones en el controlador.
- Persistencia correcta de conversaciones guiadas.
- Persistencia de la ruta y opción elegidas en conversaciones ramificadas.
- Ausencia de duplicados durante reconstrucciones.
- Creación de un segundo intento después de repetir.
- Fallo de red simulado sin bloquear la conversación.
- `flutter analyze` → sin problemas.
- 6 pruebas específicas de B101 superadas.
- Suite completa frontend → 19 pruebas superadas.
- `git diff --check` → sin errores.

### Validación manual

- Backend disponible en `http://127.0.0.1:8001`.
- Intentos guiados persistidos independientemente para `demo-user`.
- Intento ramificado `a1-u1-l1-c2` persistido con la ruta recorrida.
- Opción `a1-u1-l1-c2-choice-fine` almacenada correctamente.
- La interfaz mostró `Progreso conversacional guardado.`.

### Archivos principales

- `lib/controllers/conversation_flow_controller.dart`
- `lib/services/api_service.dart`
- `lib/widgets/lesson_conversation_card.dart`
- `lib/widgets/lesson_detail_card.dart`
- `test/conversation_flow_controller_test.dart`
- `test/lesson_conversation_card_test.dart`

### Cierre de B101

- Commit principal: `dd8fc4c` — `B101 persistir progreso conversacional`.
- Push completado a `origin/master`.
- Repositorio confirmado limpio y sincronizado después del commit principal.

## B102 — Historial y resumen del progreso conversacional

Fecha: 2026-07-22

### Objetivo

- Permitir que el usuario consulte desde la aplicación los intentos conversacionales persistidos en B101.
- Mantener el progreso conversacional separado de las estadísticas de ejercicios.

### Implementación frontend

- Se creó `ConversationAttemptRecord` para interpretar el contrato del backend.
- `ApiService.getConversationAttempts(...)` consulta `GET /api/v1/conversation-attempts/{user_id}`.
- Se creó `ConversationHistoryCard`.
- La tarjeta muestra:
  - total de intentos completados;
  - cantidad de conversaciones guiadas;
  - cantidad de conversaciones ramificadas;
  - fecha y hora de la práctica más reciente.
- Se controlan los estados de carga, historial vacío y fallo de consulta.
- `HomeScreen` actualiza el resumen al regresar de una lección.
- No se añadió ninguna dependencia nueva para formatear fechas.

### Pruebas automatizadas

- Conversión del contrato JSON y fecha con zona horaria.
- Resumen de intentos guiados y ramificados.
- Estado de historial vacío.
- Fallo de consulta controlado.
- Integración en la pantalla principal.
- 5 pruebas específicas de B102 superadas.
- Suite completa frontend: 23 pruebas superadas.
- `flutter analyze`: sin problemas.
- `git diff --check`: sin errores.

### Validación manual

- La tarjeta `Práctica conversacional` apareció correctamente.
- Datos reales mostrados:
  - intentos completados: 3;
  - guiados: 2;
  - ramificados: 1;
  - última práctica: 21/07/2026 23:53.
- No se detectaron errores visuales ni excepciones.

### Archivos principales

- `lib/models/conversation_attempt_record.dart`
- `lib/services/api_service.dart`
- `lib/widgets/conversation_history_card.dart`
- `lib/screens/home_screen.dart`
- `test/conversation_attempt_record_test.dart`
- `test/conversation_history_card_test.dart`

### Cierre de B102

- Validación final: `flutter analyze` sin problemas.
- Suite completa frontend: 23 pruebas superadas.
- Commit principal: `68e6bec` — `B102 mostrar progreso conversacional`.
- Push completado a `origin/master`.
- Repositorio confirmado limpio y sincronizado después del commit principal.

## B103 — Identificadores estables para ejemplos de pronunciación

Fecha: 2026-07-22

### Objetivo

- Adaptar Flutter al contrato backend de identificadores estables para frases de ejemplo.
- Evitar persistir futuras autoevaluaciones mediante índices que pueden cambiar al reordenar contenido.

### Implementación frontend

- `LessonExample` requiere ahora un campo `id`.
- `LessonExample.fromJson(...)` interpreta el identificador enviado por el backend.
- `LessonPronunciationControls` recibe directamente `example.id`.
- Se eliminó la construcción basada en `${lesson.id}:example:<índice>`.
- Los identificadores estables actuales son:
  - `a1-u1-l1-e1`;
  - `a1-u1-l1-e2`.
- B103 todavía no persiste autoevaluaciones ni grabaciones.

### Pruebas y validaciones

- Se creó `lesson_example_model_test.dart`.
- La prueba valida el identificador, textos y pronunciaciones del ejemplo.
- Pruebas específicas: 2 superadas.
- Suite completa frontend: 24 pruebas superadas.
- `flutter analyze`: sin problemas.
- `git diff --check`: sin errores.

### Validación manual

- El backend real devolvió los dos identificadores estables.
- Flutter realizó un hot restart sin excepciones.
- Los ejemplos `Hello, I am John.` y `Goodbye! See you later.` aparecieron correctamente.
- Las variantes regionales y la reproducción de pronunciación continuaron funcionando.
- No se detectaron errores visuales ni regresiones.

### Archivos principales

- `lib/models/lesson.dart`
- `lib/widgets/lesson_detail_card.dart`
- `test/lesson_example_model_test.dart`

### Cierre de B103

- Validación final: `flutter analyze` sin problemas.
- Suite completa frontend: 24 pruebas superadas.
- Revisión de código y seguridad completada sin cambios inesperados ni datos sensibles.
- Commit principal: `bde6fd7` — `B103 usar identificadores estables en ejemplos`.
- Push del cambio técnico completado a `origin/master`.
- Repositorio confirmado limpio y sincronizado después del commit documental.

## B104 — Producciones personales conversacionales

Fecha: 2026-07-26

### Objetivo

- Preparar Flutter para interpretar y revisar producciones personales conversacionales ya persistidas por el backend.
- Mantener separadas la producción capturada, la evaluación, el dominio, la retención y las Skills.
- No introducir persistencia de audio ni consumir contenido candidato.

### Implementación frontend

- Se añadió `LearnerProductionPrompt` como contrato opcional de `ConversationTurn`.
- El contenido activo sin `production_prompt` mantiene compatibilidad.
- Se añadieron `LearnerProductionRecord` y `ConversationProductionSubmissionRecord`.
- `ApiService` puede leer `GET /api/v1/conversation-productions/{user_id}`.
- Se creó `ConversationProductionsCard` para revisar entregas persistidas.
- La tarjeta se integró en `HomeScreen` como recurso independiente de `ConversationHistoryCard`.
- Las producciones de texto muestran su contenido.
- Las producciones de voz se muestran únicamente como registradas; `audio_reference` no se expone ni se reproduce.

### Límites explícitos de B104

- No se implementa `POST /conversation-productions`.
- No se capturan ni persisten nuevas producciones desde Flutter.
- No se persisten, suben ni reutilizan los WAV temporales actuales.
- No se interpreta `audio_reference` como una ruta local reproducible.
- No se implementa evaluación semántica o fonética.
- No se calculan puntuaciones, dominio ni retención.
- No se activa `a1-u1-l1-c3`.
- No se consume `content/candidates/`.
- `production_prompt.required` no bloquea todavía el flujo de interfaz.

### Pruebas y validaciones

- `lesson_conversation_model_test.dart` cubre `production_prompt` opcional y compatibilidad existente.
- `conversation_production_record_test.dart` cubre la deserialización de entregas y producciones persistidas.
- `conversation_productions_card_test.dart` cubre datos, estado vacío y error controlado.
- Pruebas específicas B104: 8 superadas.
- Suite completa frontend: 29 pruebas superadas.
- `flutter analyze`: sin problemas.
- `git diff --check`: sin errores.

### Archivos principales

- `lib/models/lesson.dart`
- `lib/models/conversation_production_record.dart`
- `lib/services/api_service.dart`
- `lib/widgets/conversation_productions_card.dart`
- `lib/screens/home_screen.dart`
- `test/lesson_conversation_model_test.dart`
- `test/conversation_production_record_test.dart`
- `test/conversation_productions_card_test.dart`

### Validación manual

- Backend real ejecutado en `127.0.0.1:8001` y `/api/v1/health` respondió correctamente.
- `GET /api/v1/conversation-productions/demo-user` devolvió `[]`, coherente con la ausencia de producciones visibles asociadas a contenido activo.
- Flutter se ejecutó correctamente en Linux desktop.
- La tarjeta `Producciones personales` apareció en `HomeScreen`.
- Se mostró correctamente el estado vacío: `Aún no hay producciones personales guardadas.`
- No se detectaron errores visuales ni excepciones.
- La composición actual de `HomeScreen` se mantiene como estructura funcional de desarrollo y no constituye el diseño UX definitivo.
- El rediseño global de Home queda fuera de B104 y deberá abordarse en un bloque independiente.

### Cierre de B104

- Implementación técnica completada.
- `flutter analyze`: sin problemas.
- Pruebas específicas B104: 8 superadas.
- Suite completa frontend: 29 pruebas superadas.
- `git diff --check`: sin errores.
- Validación manual contra backend real completada.
- B104 no introduce captura, evaluación, dominio, retención ni persistencia de audio.
- Commit técnico: `c1ace4e` — `B104 revisar producciones personales`.
- Pendiente únicamente commit documental, push y confirmación final de Git limpio.

## B126 — Contrato neutral de reconocimiento de voz

Fecha: 2026-07-26

### Objetivo

- Crear una frontera técnica independiente entre el audio temporal del estudiante y un futuro motor de reconocimiento de voz.
- Evitar mezclar reconocimiento técnico con evaluación pedagógica, dominio o retención de Skills.
- Preparar sustitución futura del motor STT sin acoplar widgets ni contratos pedagógicos a una tecnología concreta.

### Implementación frontend

- Se creó `SpeechRecognitionStatus` con estados `recognized`, `noSpeech` y `failed`.
- Se creó `SpeechRecognitionRequest` para describir una solicitud sobre un WAV temporal.
- La solicitud conserva contexto mediante `userId`, `levelId`, `unitId`, `lessonId`, `conversationId`, `turnId` y `promptId` opcional.
- `languageCode` pertenece al contrato de reconocimiento.
- `locale` es opcional y no reutiliza artificialmente `LessonPronunciation.locale`.
- Se creó `SpeechRecognitionResult` con transcripción y palabras reconocidas como resultado técnico.
- Se creó `SpeechRecognitionController` como interfaz independiente del motor concreto.
- Una implementación fake demuestra que el controlador puede sustituirse de forma determinista en pruebas.

### Separación de responsabilidades

- `LearnerProduction` representa lo que produjo el estudiante.
- `SpeechRecognitionResult` representa lo que un reconocedor técnico detectó.
- El reconocimiento no determina corrección semántica ni fonética.
- El reconocimiento no genera todavía `EvidenceRecord`.
- El reconocimiento no declara dominio ni retención de ninguna Skill.

### Límites explícitos de B126

- No se instaló ningún motor o dependencia STT.
- No se eligió Whisper, Vosk, Coqui, TFLite ni proveedor remoto.
- No se conectó reconocimiento a `LessonConversationCard`.
- No se modificó `PronunciationAudioService`.
- Los WAV continúan siendo estrictamente temporales y conservan la política existente de permisos y eliminación.
- No se añadió transporte de audio al backend.
- No se modificó `ApiService`.
- No se implementó evaluación semántica ni fonética.
- No se añadieron scores, confianza del motor, dominio o retención.
- No se publicó ni consumió `content/candidates/`.
- No se modificaron `production_prompt` ni los contratos pedagógicos.

### Pruebas y validaciones

- `speech_recognition_contract_test.dart` valida el contrato neutral.
- Se validó la sustitución del motor mediante fake determinista.
- Pruebas específicas B126: 2 superadas.
- Suite completa frontend: 31 pruebas superadas.
- `flutter analyze`: sin problemas.
- `git diff --check`: sin errores.

### Archivos principales

- `lib/services/speech_recognition_service.dart`
- `test/speech_recognition_contract_test.dart`

### Cierre de B126

- Contrato neutral implementado y validado.
- No se integró todavía ningún motor STT real dentro de B126.
- Commit técnico: `25c3caf` — `B126 definir contrato neutral de reconocimiento`.
- Commit documental: `d7e8913` — `docs cerrar B126 reconocimiento neutral`.
- Cambios publicados en `origin/master`.
- Git quedó limpio y sincronizado.

## B127 — Reconocimiento técnico real con Sherpa-ONNX

Fecha: 2026-07-27

### Objetivo

- Implementar el primer motor real detrás de `SpeechRecognitionController` sin modificar el contrato neutral creado en B126.
- Validar reconocimiento offline sobre los WAV existentes de la aplicación.
- Mantener reconocimiento técnico separado de evaluación semántica, evaluación fonética, evidencia pedagógica y dominio de Skills.

### Motor seleccionado y validado

- Se incorporó `sherpa_onnx 1.13.4`.
- Flutter resolvió también los paquetes nativos de plataforma, incluido `sherpa_onnx_linux 1.13.4`.
- El entorno validado es Linux `x86_64`.
- Se confirmó la presencia de `libsherpa-onnx-c-api.so`, `libsherpa-onnx-cxx-api.so` y `libonnxruntime.so`.
- Se utilizó Moonshine v1 `sherpa-onnx-moonshine-tiny-en-int8` como primer modelo de reconocimiento offline en inglés.
- El modelo probado incluye `preprocess.onnx`, `encode.int8.onnx`, `uncached_decode.int8.onnx`, `cached_decode.int8.onnx` y `tokens.txt`.
- El artefacto descargado incluye licencia MIT de Useful Sensors.

### Política de modelos

- El modelo Moonshine no se almacena en el repositorio Git.
- Durante B127 se mantuvo en:
  `~/.local/share/app-ingles/models/sherpa-onnx-moonshine-tiny-en-int8`
- Esta ubicación local resuelve únicamente la validación de desarrollo en Linux.
- B127 no decide todavía la estrategia definitiva de descarga, distribución o empaquetado de modelos para Android, iOS, Windows u otras plataformas.

### Implementación frontend

- Se creó `SherpaOnnxMoonshineModelPaths` para inyectar explícitamente las rutas del modelo.
- Se creó `SherpaOnnxRecognitionOutput` como resultado bruto independiente del contrato de aplicación.
- Se creó `SherpaOnnxRecognitionRuntime` para aislar la ejecución del motor nativo.
- Se creó `SherpaOnnxNativeRecognitionRuntime` con ejecución real de Sherpa-ONNX.
- Se mantuvo `SherpaOnnxSpeechRecognitionController` detrás de `SpeechRecognitionController`.
- La inicialización de bindings nativos es diferida y se realiza solo cuando se solicita reconocimiento.
- El runtime crea y libera explícitamente `OfflineStream` y `OfflineRecognizer`.
- Un WAV inválido o ilegible produce un fallo técnico controlado.
- Las excepciones del runtime se transforman en `SpeechRecognitionStatus.failed`.

### Estados técnicos protegidos

- `recognized`: existe una transcripción reconocida.
- `noSpeech`: el runtime termina sin texto reconocido.
- `failed`: ocurrió un fallo técnico durante el reconocimiento.

Ninguno de estos estados representa corrección pedagógica.

### Transcript, tokens y words

- Sherpa-ONNX devuelve tokens propios del tokenizer.
- Se confirmó que esos tokens no equivalen directamente a palabras.
- `SpeechRecognitionResult.words` se deriva de la transcripción final y no de `result.tokens`.
- Para el smoke probado:
  - transcript: `Hello, what is your name?`
  - words: `Hello`, `what`, `is`, `your`, `name`

### Validación real

- Se validó un WAV existente de la aplicación:
  `assets/audio/a1_u1_l1_c1_t1_us.wav`.
- Formato comprobado: mono, 16 bits, 22050 Hz.
- Sherpa-ONNX realizó internamente resampling de 22050 Hz a 16000 Hz.
- Resultado real:
  `Hello, what is your name?`
- El controlador completo devolvió:
  - `SpeechRecognitionStatus.recognized`;
  - transcript correcto;
  - words derivadas;
  - `locale=en-US`;
  - `turnId=t1`.

### Separación de responsabilidades

- `LearnerProduction` continúa representando lo producido por el estudiante.
- `SpeechRecognitionResult` representa únicamente lo detectado por reconocimiento técnico.
- `SherpaOnnxRecognitionOutput` es un detalle interno del motor.
- B127 no compara la transcripción con una respuesta esperada.
- B127 no determina pronunciación correcta o incorrecta.
- B127 no genera `EvidenceRecord`.
- B127 no actualiza mastery ni retention de ninguna Skill.

### Límites explícitos de B127

- No se conectó todavía el reconocimiento con `LessonConversationCard`.
- No se modificó `PronunciationAudioService`.
- No se cambió la política de WAV temporales.
- No se persisten archivos WAV.
- No se envía audio al backend.
- No se implementó evaluación semántica.
- No se implementó evaluación fonética.
- No se añadieron scores ni confidence.
- No se modificó `content/candidates/`.
- No se publicó la candidata pedagógica.
- No se implementó `EvidenceRecord`.
- No se modificó dominio ni retención de Skills.
- No se incorporó inteligencia artificial generativa.

### Pruebas y validaciones

- Pruebas del contrato B126 + adaptador B127: 8 superadas.
- Pruebas específicas del adaptador Sherpa: 6 superadas.
- Suite completa frontend: 37 pruebas superadas.
- `flutter analyze`: sin problemas.
- `git diff --check`: sin errores.
- Smoke real con Moonshine completado correctamente en Linux x86_64.

### Archivos principales

- `lib/services/sherpa_onnx_speech_recognition_service.dart`
- `test/sherpa_onnx_speech_recognition_service_test.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `linux/flutter/generated_plugins.cmake`
- `windows/flutter/generated_plugins.cmake`

### Cierre de B127

- Reconocimiento técnico real implementado y validado en Linux.
- El contrato neutral de B126 permanece intacto.
- El motor todavía no está conectado al flujo conversacional de usuario.
- Commit técnico: `e8734c1` — `B127 implementar reconocimiento real con Sherpa`.
- Commit documental inicial: `fdbe9fc` — `docs cerrar B127 reconocimiento Sherpa`.
- Cambios publicados en `origin/master`.
- Git quedó limpio y sincronizado.

## B128 — Reconocimiento de voz integrado en práctica conversacional

Fecha: 2026-07-27

### Objetivo

Conectar el reconocimiento técnico real de B126/B127 con la práctica conversacional del estudiante, manteniendo una separación estricta entre reconocimiento de voz y evaluación pedagógica.

### Configuración externa del modelo

- Se añadió `SpeechRecognitionConfig`.
- El directorio del modelo se recibe mediante:
  `APP_INGLES_STT_MODEL_DIR`.
- La ruta personal del entorno Linux no queda hardcodeada en el producto.
- Si no existe configuración válida o faltan artefactos del modelo, STT permanece desactivado sin romper la conversación.
- Se añadió `createConfiguredSpeechRecognitionController()` como ensamblador de infraestructura.
- El modelo Moonshine continúa fuera del repositorio.

### Integración con la aplicación

El controlador de reconocimiento se propaga mediante inyección:

`LessonDetailScreen`
→ `LessonDetailCard`
→ `LessonConversationCard`

`LessonConversationCard` continúa funcionando sin STT cuando no recibe un controlador.

### Flujo implementado

En un turno del estudiante:

1. el usuario graba su respuesta;
2. `PronunciationAudioService` produce el WAV temporal;
3. al detener la grabación se crea `SpeechRecognitionRequest`;
4. se envían contexto e identificadores disponibles:
   - usuario;
   - nivel;
   - unidad;
   - lección;
   - conversación;
   - turno;
   - `productionPrompt.id` cuando existe;
   - locale cuando existe;
5. Sherpa-ONNX procesa el audio;
6. la interfaz muestra el resultado técnico.

Estados visibles:

- `Reconociendo tu respuesta...`
- `Reconocido: <transcript>`
- `No se detectó voz en la grabación.`
- `No se pudo reconocer la grabación.`

La reproducción de la propia voz continúa siendo obligatoria antes de avanzar.

### Preprocesamiento acústico

Durante la validación real se comprobó:

- WAV del micrófono: PCM, mono, 16 bits, 44100 Hz.
- Sherpa realiza resampling interno a 16000 Hz.
- Cambiar únicamente el sample rate no resolvía el reconocimiento.
- Normalizar volumen tampoco resolvía el problema.
- Un primer recorte de silencio eliminaba pausas internas y reducía un WAV de 4.90 s a aproximadamente 0.52 s, por lo que fue descartado.
- Se confirmó que la grabación contenía:
  - aproximadamente 2.0 s de silencio inicial;
  - una pausa interna natural;
  - aproximadamente 1.07 s de silencio final.
- El comportamiento correcto fue recortar solo silencio inicial y final conservando pausas internas.
- El runtime implementa ese recorte en memoria antes de `acceptWaveform()`.
- No se introdujo FFmpeg como dependencia de la aplicación.

### Inicialización nativa Sherpa en Flutter Linux

La integración inicial utilizaba `Isolate.resolvePackageUri(...)`, válida durante el smoke ejecutado con `dart run`, pero no soportada dentro del runtime Flutter Linux.

Error real observado:

`Unsupported operation: Isolate.resolvePackageUriSync`

Se confirmó que `sherpa_onnx_linux 1.13.4` incluye en su bundle:

- `libsherpa-onnx-c-api.so`;
- `libonnxruntime.so`.

La inicialización se corrigió para Flutter Linux mediante:

`sherpa.initBindings()`

permitiendo que la librería cargue el artefacto nativo empaquetado por el plugin.

### Validación real en aplicación

Se arrancó Flutter Linux con:

`--dart-define=APP_INGLES_STT_MODEL_DIR=<directorio-modelo>`

y se recorrió manualmente:

`Meeting someone`
→ interlocutor
→ `Tu respuesta`
→ grabación real
→ detener
→ reconocimiento.

Resultado visible confirmado:

`Reconocido: Hello, I am John.`

La misma arquitectura conserva el WAV temporal y no envía audio al backend.

### Separación pedagógica

B128 reconoce lo que el estudiante dijo, pero no determina si estuvo bien o mal.

No se implementó:

- comparación semántica con respuesta esperada;
- evaluación fonética;
- score de pronunciación;
- confidence pedagógica;
- `EvidenceRecord`;
- mastery;
- retention;
- modificación de Skills;
- generación con IA.

### Archivos principales

- `lib/services/speech_recognition_config.dart`
- `lib/services/speech_recognition_factory.dart`
- `lib/services/sherpa_onnx_speech_recognition_service.dart`
- `lib/screens/lesson_detail_screen.dart`
- `lib/widgets/lesson_detail_card.dart`
- `lib/widgets/lesson_conversation_card.dart`
- `test/lesson_conversation_card_test.dart`

### Pruebas y validaciones

- Pruebas específicas B126/B127/B128: superadas.
- Suite completa frontend: 37 pruebas superadas.
- `flutter analyze`: sin problemas.
- `git diff --check`: sin errores.
- Validación manual real con micrófono y Sherpa-ONNX: correcta.

### Estado previo al cierre

- Capacidad técnica y experiencia visible de B128 implementadas.
- Reconocimiento real validado dentro de Flutter Linux.
- Separación reconocimiento/evaluación preservada.
- Pendiente únicamente versionar, publicar y confirmar Git limpio.

## B181 — Ejecución audio-first y persistencia de conversación breve

Fecha: 2026-08-08

### Objetivo

Permitir que el estudiante ejecute en Flutter `a1-u1-l2-c1` de extremo a extremo:

- escuchar primero cada intervención del interlocutor;
- revelar opcionalmente el transcript solo después de escuchar;
- responder tres veces por voz;
- recibir apoyo visible decreciente `anchors → initial_word → none`;
- conservar las tres grabaciones;
- subir los tres WAV;
- enviar una única `ConversationProductionSubmission` al backend.

### Contexto

B181 Incremento 1 ya había definido y publicado `a1-u1-l2`, `Keep the conversation going`. Los ocho audios US/UK ya estaban publicados y aprobados.

El backend existente ya disponía de:

- `POST /api/v1/conversation-production-audio`;
- `POST /api/v1/conversation-productions`;
- `ConversationProductionSubmission`;
- `LearnerProduction`.

No fue necesario modificar backend.

### Contrato B181 conservado en Flutter

Los modelos Flutter conservan ahora las extensiones necesarias recibidas desde backend:

- `audio_first_policy`;
- `production_function`;
- `primary_modality`;
- `fallback_modalities`;
- `support_level`;
- `visible_support`;
- `allow_full_answer_model`;
- `interaction_function`.

La ampliación es retrocompatible: las conversaciones anteriores que no declaran estos campos conservan su deserialización y comportamiento previos.

### Flujo audio-first

En B181, el transcript del interlocutor comienza oculto. El estudiante debe escuchar el audio al menos una vez antes de que aparezca la acción explícita para revelar el transcript y puede repetir la reproducción. Revelarlo es una contingencia o medida de accesibilidad: representa comprensión asistida, no exclusivamente auditiva, y no muestra una respuesta modelo del estudiante.

Las conversaciones heredadas sin política audio-first conservan su comportamiento anterior.

### Apoyo visible

Los tres prompts muestran exactamente el apoyo recibido desde backend:

- primera respuesta: `anchors`;
- segunda respuesta: `initial_word`;
- tercera respuesta: `none`.

Flutter no genera, completa ni reconstruye respuestas. Cuando el nivel es `none`, no añade ayuda visible.

### Producciones reales

- Las grabaciones se conservan durante toda la conversación.
- Se indexan mediante `prompt_id` y mantienen su asociación con `turn_id`.
- Regrabar un turno sustituye únicamente la grabación correspondiente a ese prompt.
- Las tres grabaciones sobreviven hasta el envío.
- Tras una submission correcta, se eliminan los temporales correspondientes.
- Los temporales también se limpian al reiniciar o disponer conforme al ciclo de vida existente.

La voz permanece como modalidad principal y cada producción enviada conserva su identidad sin crear una representación paralela.

### Integración backend

Para la conversación B181 en modo `free`:

1. se suben los tres WAV mediante `POST /api/v1/conversation-production-audio`;
2. cada subida devuelve una referencia `production-audio://...`;
3. se construyen las tres producciones con sus `prompt_id`, `turn_id`, modalidad y referencia de audio;
4. se envía una sola `ConversationProductionSubmission` mediante `POST /api/v1/conversation-productions`.

No se crea almacenamiento paralelo. La conversación B181 `free` no llama a `conversation-attempts`. Los flujos heredados `guided` y `branching` conservan su persistencia previa mediante `conversation-attempts`.

### Reconocimiento de voz

El reconocimiento técnico existente puede continuar funcionando, pero permanece separado de:

- comprensión;
- pertinencia de la respuesta;
- evaluación pedagógica;
- progreso;
- mastery.

El reconocimiento no se convierte en evidencia de comprensión.

### Separación pedagógica

- producción persistida ≠ comprensión demostrada;
- reconocimiento técnico ≠ intención comprendida;
- transcript revelado ≠ modalidad normal;
- conversación recorrida ≠ éxito pedagógico;
- tres respuestas guardadas ≠ progreso;
- tres respuestas guardadas ≠ mastery.

La interfaz distingue entre haber recorrido la conversación y haber guardado las respuestas, sin afirmar comprensión o aprendizaje. No se implementaron scoring, semántica automática, adaptación ni Karaoke Fonético.

### Brechas conscientemente fuera

- El uso del transcript permanece como estado local y no se persiste.
- No se implementó todavía texto como modalidad fallback.
- No se implementaron resultados efectivos de revisión:
  - `intention_understanding`;
  - `contingent_response`;
  - `positive | negative | pending`.
- No existe rollback remoto de WAV ya subidos si un upload posterior o la submission falla.
- No se añadió backend nuevo para resolver estas brechas.

Estas brechas son límites explícitos del incremento, no errores de la capacidad implementada.

### Archivos principales

- `lib/models/lesson.dart`
- `lib/services/api_service.dart`
- `lib/widgets/lesson_conversation_card.dart`
- `test/lesson_conversation_card_test.dart`
- `test/lesson_conversation_model_test.dart`

### Pruebas y validaciones

- Pruebas focales finales: 9 passed.
- `flutter analyze`: correcto.
- Regresión frontend relacionada: 36 passed.
- Suite frontend completa final: 39 passed.
- `git diff --check`: limpio.

La primera ejecución focal detectó un defecto exclusivamente en el doble de audio de prueba. Se corrigió la notificación de fin de grabación del doble y la repetición quedó validada; la evidencia no demuestra un defecto del runtime productivo.

### Trazabilidad

Commit técnico frontend ya creado: `8baf7a6 feat ejecutar conversación audio-first B181`. Todavía no está publicado.

### Estado previo al cierre

- Capacidad técnica implementada.
- Postflight superado.
- Backend sin cambios.
- Incremento 2 documentado; quedan pendientes versionar esta documentación, publicar los commits y confirmar Git limpio.
- B181 permanece abierto y no queda integralmente cerrado.
- No se define un Incremento 3 ni un siguiente mecanismo en este punto.

## B182 — Incremento 1: shell visual y navegación principal de LOGUIC English

Fecha: 2026-08-09

### Objetivo

Establecer la base visual canónica de LOGUIC English para que, al abrir la aplicación, el usuario reconozca la marca y pueda navegar entre cinco destinos principales mediante un shell persistente y responsive, sin reescribir ni desplazar las capacidades funcionales existentes.

La referencia visual es el segundo mockup aprobado de LOGUIC English:

- marca: `LOGUIC English`;
- eslogan: `Escucha. Habla. Lee. Avanza.`;
- destinos: `Inicio`, `Niveles`, `Aprender`, `Repaso` y `Perfil`.

### Arquitectura del shell

- `MainShellScreen` centraliza los cinco destinos mediante un `IndexedStack` y conserva el estado compartido al cambiar de sección.
- `LoguicTheme` centraliza colores, superficies, espaciado, radios, tipografía y estilos de navegación.
- En escritorio, desde `900 px`, se utiliza una sidebar navy/índigo persistente con marca compacta y destino activo resaltado.
- En móvil y tablet se conserva una navegación inferior persistente.
- Ambos formatos comparten los mismos destinos y estado; no se crearon aplicaciones o flujos paralelos.
- `LessonDetailScreen` continúa abriéndose con `Navigator` desde `Aprender`.
- Al regresar de una lección se conserva el refresco existente de progreso, historial conversacional y producciones personales.

No se introdujo un router nuevo ni se modificó la semántica de navegación interna de las lecciones.

### Composición visual de Inicio

Inicio presenta una composición centrada y de anchura limitada sobre un fondo claro ligeramente azulado. El progreso actual ocupa la posición visual prioritaria y la práctica conversacional, su historial y las producciones personales quedan como información secundaria en tarjetas compactas y responsive.

La pantalla reutiliza exclusivamente datos reales que ya estaban disponibles:

- ejercicios respondidos;
- respuestas correctas;
- historial conversacional;
- producciones personales.

No se inventaron rachas, minutos de estudio, puntuaciones, rutas por objetivos ni métricas familiares. La tarjeta técnica visible `Estado del backend` dejó de formar parte del primer plano de Inicio, sin alterar las llamadas funcionales restantes.

### Destinos provisionales

- `Niveles` reutiliza temporalmente el selector existente; todavía no implementa el mapa visual A1–C2.
- `Aprender` reutiliza la navegación existente de unidades y lecciones; todavía no rediseña el detalle de lección.
- `Repaso` muestra una superficie neutral e indica que la capacidad aún no está disponible, sin simular adaptación ni datos.
- `Perfil` muestra una superficie neutral, sin inventar usuario, familia, autenticación, estadísticas ni progreso familiar.

### Compatibilidad funcional

El incremento conserva sin cambios la lógica y los contratos de:

- `LessonConversationCard`;
- `LessonPronunciationControls`;
- `ConversationFlowController`;
- servicios de audio y reconocimiento;
- uploads y persistencia;
- modelos pedagógicos;
- backend.

La separación del shell es visual y de composición. No mueve todavía pronunciación, conversación, ejercicios ni persistencia a nuevas pantallas.

### Validación visual humana

La aplicación se ejecutó en Linux y se comparó con el mockup canónico. La puerta visual humana quedó aprobada como base del shell por incorporar:

- sidebar navy/índigo;
- composición compacta de marca y eslogan;
- destino activo resaltado;
- fondo principal claro;
- contenido centrado y limitado;
- tarjetas más compactas;
- una composición reconocible como LOGUIC English.

Esta aprobación valida la base canónica del shell; no significa que Inicio ni los demás destinos estén terminados visualmente.

### Pruebas y validaciones

- Pruebas focales del shell: 5 passed.
- Regresión relacionada de lista y detalle: 2 passed.
- `flutter analyze`: `No issues found`.
- Suite frontend completa final: 43 tests passed.
- `git diff --check`: limpio.
- Validación visual humana en Linux: aprobada.

### Trazabilidad

Commit técnico: `0869439 feat añadir shell visual LOGUIC English`.

### Deudas conscientes

Permanecen fuera de este incremento, sin funcionalidades simuladas:

- rediseño específico de Inicio;
- mapa visual A1–C2;
- detalle de lección canónico;
- pantalla independiente de pronunciación;
- pantalla independiente de conversación;
- lectura guiada;
- misión de fluidez;
- repaso adaptativo real;
- perfil y progreso familiar reales.

### Relación con B181

B181 permanece abierto y pausado por dependencia de interfaz. Debe retomarse desde su demostración humana pendiente cuando la superficie correspondiente esté preparada. B182 no cierra B181 ni modifica su implementación.

### Estado del incremento

- Shell visual y navegación principal implementados.
- Validaciones automatizadas y análisis estático superados.
- Puerta visual humana aprobada como base canónica.
- Incremento 1 técnicamente cerrado y trazado por `0869439`.
- Las pantallas específicas posteriores permanecen fuera de alcance.

## B181 — Checkpoint frontend posterior a demostración humana

Fecha: 2026-08-11

Durante la demostración humana B181 se detectó que un fallo de upload podía dejar tres grabaciones válidas sin una posibilidad clara de reintentar su persistencia. Se añadió un retry manual que reutiliza las grabaciones existentes, evita el doble envío, limpia las grabaciones solo después del éxito y conserva detalle útil del error backend o HTTP.

La evidencia humana también demostró una ambigüedad entre consigna y respuesta. La UX se corrigió mediante «Responde con tus palabras», «Qué debes hacer» y «Responde con información propia. No repitas la instrucción.», con tratamiento diferenciado de `anchors`, `initial_word` y `none`. La nueva microcopy fue comprendida durante la segunda validación humana.

Validaciones vigentes:

- test focal: PASS;
- `flutter analyze`: PASS;
- `git diff --check`: PASS;
- suite frontend completa: 44 passed.

Commit técnico: `aabe4a4 fix corregir reintento y consigna B181`. El commit todavía no se declara publicado en `origin`.

B181 continúa **PAUSADO EN PUERTA PEDAGÓGICA — NO CERRADO INTEGRALMENTE**. La pausa ya no responde a un fallo de interfaz ni a una revisión humana pendiente. Su reanudación depende de la futura construcción pedagógica canónica A1 y de la revisión del Constructor Pedagógico.

## B183 — Checkpoint Visual Flutter: recorrido demo A1 de LOGUIC English

Fecha: 2026-08-27

### Estado del bloque

Contrato definido. Implementación pendiente.

Este bloque es el primer slice del Checkpoint Visual Flutter posterior a B182. Evoluciona la shell canónica existente y no crea una aplicación, navegación o arquitectura paralela.

### Capacidad observable

Al abrir LOGUIC English, el usuario puede iniciar desde `Inicio` un recorrido de demostración, explorar un mapa visual A1–C2, entrar en una portada demo A1, realizar una experiencia de escucha/pronunciación y recorrer una conversación breve. Puede avanzar y volver realmente entre todas las superficies sin que la aplicación atribuya progreso, aprendizaje, comprensión o mastery.

El recorrido observable es:

`Inicio → mapa visual A1–C2 → portada demo A1 → escucha/pronunciación → conversación breve → retorno`

### Alcance visual exacto

#### Inicio evolucionado

- Conserva `HomeScreen` dentro de `MainShellScreen`.
- Añade un CTA visible para iniciar o continuar exclusivamente la demostración visual.
- Mantiene la identidad `LOGUIC English` y el eslogan `Escucha. Habla. Lee. Avanza.`.
- No convierte los datos reales actualmente visibles en indicadores del recorrido demo.
- El CTA no escribe progreso ni implica que el usuario haya iniciado un itinerario curricular.

#### Mapa visual A1–C2

- Sustituye, para la experiencia visual acordada, la presentación provisional basada únicamente en chips por un mapa claro de los seis niveles `A1`, `A2`, `B1`, `B2`, `C1` y `C2`.
- `A1` aparece activo únicamente como puerta de entrada a la demostración.
- `A2–C2` aparecen como horizonte del producto, sin porcentajes, bloqueos por rendimiento, estrellas, rachas, puntuaciones ni estados de dominio inventados.
- La activación visual de `A1` significa `demo disponible`, no nivel asignado, recomendado, iniciado o dominado.

#### Portada demo A1

- Presenta una situación cotidiana provisional mediante contexto visual, título demo, propósito demostrativo y acceso claro a las dos experiencias del slice.
- Expone accesos a `Escucha y pronunciación` y `Conversación breve`.
- No presenta unidades, Skills, secuencias curriculares ni criterios pedagógicos como aprobados.
- No reutiliza `a1-u1-l1` como contenido curricular ni editorial canónico.

#### Escucha y pronunciación

- Ofrece una experiencia ejecutable de escucha, grabación, reproducción de la propia voz y repetición.
- Aplica la secuencia de ayudas: contexto visual → pista breve → transcript disponible después de la primera escucha → traducción al español como rescate opcional independiente.
- Ni el transcript ni la traducción se muestran antes de completar la primera escucha.
- Revelar transcript no revela automáticamente la traducción.
- Completar la práctica no genera corrección, puntuación, progreso, aprendizaje ni evidencia de mastery.

#### Conversación breve

- Ofrece una conversación demo ejecutable y claramente provisional.
- Reutiliza el flujo conversacional existente y mantiene separadas navegación conversacional, audio, reconocimiento técnico y significado pedagógico.
- Aplica, cuando corresponda, la misma progresión de ayudas: contexto visual → pista breve → transcript tras escucha → traducción como rescate opcional.
- Puede registrar audio temporal para ejecutar la experiencia, pero no lo sube ni persiste.
- Su final declara únicamente que el recorrido demo terminó; no declara comprensión, éxito pedagógico, progreso ni mastery.

#### Navegación real

- Todas las superficies forman parte de la shell canónica o se abren desde ella mediante la navegación Flutter ya existente.
- Existe avance explícito entre cada superficie y retorno a la superficie anterior.
- El usuario puede volver desde escucha o conversación a la portada demo, desde la portada al mapa y desde el mapa a Inicio.
- En escritorio se conserva la navegación lateral; en móvil y tablet, la navegación inferior.
- No se incorpora un router nuevo para este slice.

### Reutilización obligatoria

La implementación debe evolucionar y reutilizar:

- `MainShellScreen` como única shell canónica;
- `LoguicTheme` y sus tokens visuales;
- navegación responsive existente;
- `PronunciationAudioController` y el servicio actual de audio/grabación;
- `LessonPronunciationControls` para la mecánica de escucha y repetición, adaptándolo solo en lo mínimo necesario para el modo demo;
- `LessonConversationCard` y su máquina de estados cuando su comportamiento coincida con la demo;
- `ConversationFlowController` como única lógica de avance por turnos;
- modelos de pronunciación y conversación compatibles, sin introducir un segundo grafo conversacional;
- patrones existentes de inyección para aislar widgets de servicios externos en tests.

No se copiarán máquinas de estados, coordinación de grabación, selección regional, avance conversacional ni lógica de reproducción en widgets exclusivos del checkpoint.

### Modelo y fixture local provisional

El slice utiliza un modelo de presentación y una fixture local mínimos, exclusivos del checkpoint visual.

Condiciones obligatorias:

- están separados de las fuentes y contratos curriculares;
- no se cargan desde backend;
- no constituyen ni anticipan el loader;
- usan un namespace inequívoco de demo, por ejemplo `demo-visual-a1-*`;
- nunca usan `a1-u1-l1` como identificador, alias o fuente editorial;
- tampoco presentan el contenido B181 como currículo aprobado;
- viven solo en memoria y no escriben progreso, intentos ni producciones;
- no contienen Skills, mastery, scoring ni criterios de aprobación;
- pueden contener únicamente el texto, contexto visual y referencias de audio imprescindibles para sentir el recorrido.

Todas las superficies demo muestran de forma visible y legible la rotulación exacta:

`Demostración visual · Contenido provisional · No representa el currículo A1 definitivo`

### Fronteras semánticas obligatorias

- demo visual ≠ currículo aprobado;
- navegación ≠ progreso;
- completar recorrido ≠ aprendizaje;
- conversación realizada ≠ mastery;
- audio grabado ≠ pronunciación evaluada;
- transcript revelado ≠ comprensión demostrada;
- traducción consultada ≠ fracaso o éxito pedagógico;
- checkpoint visual ≠ cierre de B181.

B181 permanece pausado en puerta pedagógica y este bloque no modifica su estado, contrato, contenido ni evidencia.

### Fronteras técnicas

Queda prohibido para B183:

- modificar backend;
- diseñar o implementar loader;
- modificar endpoints, payloads o contratos API;
- autenticar usuarios;
- añadir adaptación;
- realizar evaluación semántica o fonética;
- guardar progreso real;
- llamar a endpoints de progreso, intentos, uploads o producciones desde el recorrido demo;
- convertir reconocimiento técnico en juicio pedagógico;
- introducir persistencia local sustitutiva.

### Estrategia mínima para audio y conversación

- La fixture demo se adapta a los modelos consumidos por los componentes actuales en vez de crear modelos paralelos de ejecución.
- `LessonPronunciationControls` continúa siendo propietario del flujo escuchar → grabar → revisar → repetir.
- `ConversationFlowController` continúa resolviendo turnos y finalización.
- `LessonConversationCard` conserva una única implementación del flujo visual conversacional. Si necesita distinguir la demo, se incorporará una política interna, explícita e inyectable de ejecución sin persistencia cuyo valor por defecto preserve íntegramente el comportamiento actual.
- La política demo no simula respuestas exitosas del backend: desactiva de forma explícita uploads y submissions.
- Cualquier extracción de widgets será limitada a presentación reutilizable; no duplicará estado o efectos.
- Los archivos temporales de grabación se limpian con el ciclo de vida existente y nunca se convierten en evidencia persistida.

### Archivos candidatos para la implementación posterior

La lista es orientativa y debe mantenerse mínima durante la implementación.

Archivos existentes candidatos a modificar:

- `lib/screens/main_shell_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/theme/loguic_theme.dart`
- `lib/widgets/lesson_pronunciation_controls.dart`
- `lib/widgets/lesson_conversation_card.dart`
- `test/main_shell_screen_test.dart`
- `test/lesson_pronunciation_controls_test.dart`
- `test/lesson_conversation_card_test.dart`
- `test/widget_test.dart`
- `docs/bitacora-frontend.md`

Archivos candidatos a crear, solo si la composición lo requiere:

- `lib/models/visual_demo_content.dart`
- `lib/data/visual_demo_fixture.dart`
- `lib/screens/visual_demo_lesson_screen.dart`
- `lib/screens/visual_demo_listening_screen.dart`
- `lib/screens/visual_demo_conversation_screen.dart`
- `lib/widgets/visual_level_map.dart`
- `lib/widgets/visual_demo_notice.dart`
- `lib/widgets/visual_context_card.dart`
- `test/visual_demo_fixture_test.dart`
- `test/visual_demo_flow_test.dart`

No se crean todos por defecto. Se favorecerá la menor cantidad que preserve separación de responsabilidades, legibilidad y reutilización.

### Tests contractuales mínimos esperados

La implementación posterior debe añadir pruebas focales que demuestren:

1. Inicio muestra el CTA demo sin alterar la shell ni los cinco destinos.
2. El CTA abre el mapa A1–C2.
3. El mapa muestra exactamente A1, A2, B1, B2, C1 y C2.
4. Solo A1 abre la demo y A2–C2 no muestran progreso, porcentajes ni mastery.
5. Todas las superficies demo muestran la rotulación provisional exacta.
6. Ningún ID de fixture coincide con `a1-u1-l1` ni usa el namespace curricular existente.
7. La portada abre escucha y conversación y permite volver al mapa.
8. Escucha exige una primera reproducción antes de ofrecer transcript.
9. La traducción permanece oculta hasta una acción de rescate separada y no aparece al revelar transcript.
10. Pronunciación reutiliza reproducción/grabación y puede repetirse sin persistencia.
11. Conversación avanza mediante el flujo existente, termina con mensaje neutral y permite volver.
12. La demo no invoca progreso, `conversation-attempts`, uploads ni `conversation-productions`.
13. El comportamiento persistente heredado de pronunciación y conversación no cambia fuera del modo demo.
14. La navegación se mantiene operativa en viewport móvil y escritorio.

No forman parte de este contrato pruebas de contenido pedagógico, scoring, evaluación de pronunciación, backend ni loader.

### Criterios de aceptación

1. La aplicación ofrece el recorrido completo `Inicio → mapa → portada A1 → escucha/pronunciación → conversación → retorno`.
2. `MainShellScreen` sigue siendo la única shell y conserva su navegación responsive.
3. Inicio contiene un CTA demo claro y no atribuye progreso por utilizarlo.
4. El mapa presenta A1–C2; A1 es la única demo activa y A2–C2 son horizonte neutral.
5. Cada superficie demo muestra literalmente `Demostración visual · Contenido provisional · No representa el currículo A1 definitivo`.
6. La fixture usa IDs `demo-visual-*`, nunca `a1-u1-l1`, y no se confunde con contenido curricular.
7. La escucha/pronunciación es ejecutable mediante los servicios existentes.
8. Las ayudas respetan el orden contexto visual → pista breve → transcript tras primera escucha → traducción opcional separada.
9. La conversación breve es ejecutable mediante la lógica existente y no persiste producciones ni intentos.
10. Finalizar cualquier superficie muestra lenguaje neutral, sin afirmar comprensión, corrección, aprendizaje, progreso o mastery.
11. El recorrido permite avanzar y volver realmente en móvil y escritorio.
12. No existen llamadas demo a backend, cambios de API, loader, autenticación, adaptación o evaluación.
13. B181 permanece pausado y sin modificaciones.
14. Las capacidades existentes fuera del modo demo conservan su comportamiento.

### Definition of Done

B183 estará terminado únicamente cuando:

- el recorrido visual completo esté implementado y sea ejecutable;
- la revisión de código confirme reutilización y ausencia de máquinas de estado duplicadas;
- la fixture provisional esté aislada, rotulada y libre de IDs curriculares prohibidos;
- audio, grabación y conversación funcionen sin persistencia en modo demo;
- transcript y traducción cumplan la progresión contingente acordada;
- los tests contractuales focales y regresiones relacionadas pasen mediante ejecución Bash-first;
- `flutter analyze` pase mediante ejecución Bash-first;
- una validación visual humana compruebe claridad A1, tono alentador, paleta índigo, navegación y legibilidad responsive;
- la bitácora registre implementación, evidencia, límites y deuda consciente sin declarar currículo aprobado;
- no haya cambios en backend, loader ni contratos API;
- B181 continúe explícitamente pausado;
- el worktree del bloque esté comprendido y listo para la decisión posterior de commit, sin que este contrato autorice commit o push.

### Riesgos y mitigaciones mínimas

- **Shell o navegación duplicadas:** integrar todas las entradas en `MainShellScreen` y conservar `Navigator` donde ya se utiliza.
- **Contenido demo convertido en currículo:** namespace `demo-visual-*`, fixture separada y aviso literal visible.
- **Persistencia accidental:** política demo explícita sin persistencia y dobles espía que fallen ante cualquier llamada prohibida.
- **Lógica de audio duplicada:** reutilizar `LessonPronunciationControls` y `PronunciationAudioController`.
- **Lógica conversacional duplicada:** reutilizar `LessonConversationCard` y `ConversationFlowController`, extrayendo solo presentación si resulta imprescindible.
- **Regresiones B181:** comportamiento por defecto inalterado y pruebas focales heredadas ejecutadas después mediante Bash-first.
- **Progreso o mastery inventados:** lenguaje neutral y mapa sin métricas, estados de dominio ni desbloqueos por rendimiento.
- **Traducción presentada como ayuda primaria:** estado independiente, oculto y disponible solo tras la escucha.
- **Arquitectura visual desechable:** componentes pequeños guiados por `LoguicTheme`, sin segunda librería de estilos ni shell paralela.
- **Alcance expansivo:** limitar el slice a una sola situación demo y a las cinco superficies acordadas.

### Fuera de alcance

- currículo A1 definitivo y cualquier validación pedagógica de su contenido;
- uso canónico de `a1-u1-l1`;
- cierre o reanudación de B181;
- mapa curricular funcional o desbloqueos reales A1–C2;
- progreso, mastery, scoring, rachas, puntos o recomendaciones;
- persistencia de navegación, escucha, grabaciones o conversación demo;
- backend, base de datos, endpoints, contratos API y loader;
- autenticación, perfiles y progreso familiar;
- repaso adaptativo;
- adaptación o personalización;
- reconocimiento convertido en evaluación;
- evaluación semántica, fonética o de intención;
- contenido definitivo, múltiples lecciones demo o producción masiva de assets;
- lectura guiada, misión de fluidez y Karaoke Fonético;
- rediseño general de widgets no necesarios para el recorrido;
- commit, push o despliegue como parte de la definición contractual.
