# App Inglés Engineering System v2

## 1. Propósito

Este documento define el sistema profesional de ingeniería para desarrollar App Inglés de forma rápida, segura, trazable y sostenible.

La aplicación está orientada a la conversación fluida, la práctica oral real y el aprendizaje activo. No busca replicar modelos como Duolingo, sino construir una experiencia inspirada en la interacción natural, la inmersión y la personalización pedagógica.

## 2. Principios de ingeniería

1. Producto y aprendizaje antes que tecnología.
2. Entregas pequeñas con valor real para el usuario.
3. Desarrollo mediante capacidades verticales.
4. Arquitectura evolutiva, sin sobreingeniería.
5. Pruebas automáticas para comportamientos importantes.
6. Seguridad integrada durante todo el ciclo de vida.
7. Documentación viva y trazabilidad.
8. Automatización de validaciones mediante CI.
9. Revisión de código antes de cada entrega.
10. IA como acelerador, nunca como sustituto de la validación.

## 3. Flujo de trabajo por capacidad

Cada bloque funcional seguirá este flujo:

1. Problema real del usuario.
2. Resultado pedagógico esperado.
3. Criterios de aceptación.
4. Diseño mínimo de la solución.
5. Implementación vertical.
6. Pruebas.
7. Revisión de seguridad.
8. Revisión de calidad.
9. Documentación.
10. Commit, push y repositorio limpio.

## 4. Desarrollo por cortes verticales

No se crearán widgets, servicios o modelos aislados sin una capacidad funcional asociada.

Ejemplo de capacidad vertical:

> El usuario escucha una frase, la repite, recibe retroalimentación y guarda su progreso.

Una capacidad puede incluir cambios coordinados en:

* interfaz;
* modelos;
* servicios;
* backend;
* almacenamiento;
* pruebas;
* documentación.

## 5. Criterios de aceptación

Antes de programar una capacidad se debe definir qué comportamiento observable debe cumplir.

Ejemplo:

* El usuario puede reproducir una frase.
* Puede iniciar y detener una grabación.
* La aplicación muestra el estado de la práctica.
* Los errores se gestionan sin bloquear la aplicación.
* El progreso se guarda correctamente.

## 6. Definition of Done

Un bloque solo se considera terminado cuando cumple:

* capacidad funcional implementada;
* criterios de aceptación cumplidos;
* `flutter analyze` sin errores;
* pruebas necesarias aprobadas;
* revisión de seguridad realizada;
* revisión de código realizada;
* documentación actualizada;
* commit y push completados;
* Git limpio y sincronizado.

## 7. Estrategia de pruebas

Se utilizarán progresivamente:

* pruebas unitarias para lógica y modelos;
* pruebas de widgets para comportamiento visual;
* pruebas de integración para flujos completos;
* validaciones manuales únicamente cuando no puedan automatizarse todavía.

No será suficiente ejecutar pruebas existentes. Cada comportamiento crítico deberá incorporar su prueba correspondiente.

## 8. Arquitectura evolutiva

La arquitectura se modificará solo cuando exista un problema real:

* archivos demasiado grandes;
* lógica duplicada;
* dificultad para probar;
* dependencia excesiva entre capas;
* dificultad para añadir nuevas funciones;
* riesgo de romper funcionalidades existentes.

La evolución podrá orientarse hacia módulos por funcionalidad:

```text
features/
  lessons/
  speaking/
  listening/
  progress/
  practice/
```

Cada funcionalidad podrá separar gradualmente:

* presentación;
* dominio;
* datos.

No se realizará una migración masiva sin necesidad confirmada.

## 9. Revisión de código

Antes de cerrar cada bloque se revisará:

* funcionamiento;
* diseño;
* complejidad;
* nombres;
* duplicación;
* manejo de errores;
* pruebas;
* comentarios y documentación;
* consistencia;
* accesibilidad;
* seguridad;
* impacto en funcionalidades existentes.

Cada cambio debe mejorar o mantener la salud general del código.

## 10. Integración continua

Se incorporará GitHub Actions para ejecutar automáticamente:

```bash
flutter analyze
flutter test
```

La validación automática complementará, pero no sustituirá, la validación local.

Una integración rota tendrá prioridad de corrección antes de continuar desarrollando.

## 11. DevSecOps

La seguridad se aplicará desde el diseño.

Se revisará progresivamente:

* gestión de secretos;
* variables de entorno;
* permisos mínimos;
* validación de entradas;
* validación de respuestas del backend;
* protección de datos del usuario;
* dependencias vulnerables;
* registros sin información sensible;
* exposición de audio y datos personales;
* autenticación y autorización;
* riesgos relacionados con IA;
* costes y límites de consumo de servicios externos.

## 12. Métricas de ingeniería

Se registrarán métricas ligeras:

* tiempo desde idea hasta funcionalidad terminada;
* frecuencia de bloques cerrados;
* errores introducidos;
* tiempo de recuperación;
* retrabajo;
* pruebas añadidas;
* deuda técnica detectada.

No se medirá productividad por cantidad de líneas de código.

## 13. Uso profesional de IA

La IA podrá ayudar a:

* analizar requisitos;
* proponer diseños;
* generar código;
* generar pruebas;
* revisar seguridad;
* detectar inconsistencias;
* actualizar documentación;
* diseñar contenido pedagógico;
* acelerar tareas repetitivas.

Todo resultado generado por IA deberá ser revisado, probado y documentado.

## 14. Prioridades del producto

El orden de prioridad será:

1. conversación fluida;
2. comprensión auditiva;
3. práctica oral;
4. retroalimentación pedagógica;
5. personalización;
6. progreso adaptativo;
7. repetición inteligente;
8. experiencia atractiva;
9. escalabilidad;
10. automatización.

## 15. Estrategia de entrega

La app avanzará mediante capacidades completas y demostrables.

Las próximas etapas deberán priorizar:

* escucha de frases;
* reproducción de audio;
* repetición guiada;
* grabación de voz;
* comparación y retroalimentación;
* práctica conversacional;
* rutas adaptativas según errores;
* integración progresiva de IA.

El objetivo es construir una versión innovadora en tres meses mediante alcance controlado, reutilización de servicios y entregas verticales frecuentes.
