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

