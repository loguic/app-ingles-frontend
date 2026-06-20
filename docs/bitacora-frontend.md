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