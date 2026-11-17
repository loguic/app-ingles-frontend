---
name: loguic-uiux-design-review
description: Revisa interfaces Flutter de LOGUIC English antes de aprobar diseño: fidelidad a maquetas, responsive, contraste, accesibilidad, jerarquía pedagógica y estados deshabilitados. Usar en Human Review Gate de UI/UX, especialmente al revisar capturas o cambios de pantallas; no usar para implementación general ni sustituir la aprobación humana.
---

# LOGUIC UI/UX Design Review v1

**Estado de la decisión:** APPROVED / HUMAN · 2026-11-16. **Ámbito:** LOGUIC English (piloto local). No es una nueva autoridad de arquitectura ni un agente autónomo.

## Autoridades y precedencia

1. Ejecutar el Startup Gate **existente** del proyecto (`conversation_checkpoint.py resume --format compact`) antes de cualquier inspección técnica que dependa del repositorio. Si falla: **STOP** y reconciliar las autoridades canónicas según el método vigente. No asumir que el contenido de esta skill desplaza al roadmap, contratos pedagógicos, maquetas previamente aprobadas o decisiones humanas.
2. Leer solo las partes necesarias de `docs/estado-operativo.md`, `docs/roadmap.md`, `docs/bitacora.md` y las normas de ingeniería pertinentes; no lanzar auditorías globales sin motivo.
3. Respetar el flujo aprobado: **Requisitos → Flujos de usuario → Maquetas → Prototipo navegable → Arquitectura → Implementación incremental → Pruebas integrales → Entrega**; DevOps/DevSecOps transversales.
4. Integrarse en **Weekly Goals v1**: un objetivo activo, una intervención verificable, evidencia breve y mínimo consumo de tokens. Para revisar, priorizar las herramientas canónicas y la inspección humana; usar IA local para casos no deterministas. No usar Codex para verificaciones deterministas. Si dos intervenciones de IA no aportan avance funcional: STOP.

## Activación y límites

Activar cuando se revise una pantalla nueva, un cambio visual, una discrepancia con la maqueta o un defecto responsive/accesible, o cuando se solicite expresamente una revisión UI/UX. No ejecutar en segundo plano ni en cada cambio de código. Inicialmente **solo lectura y diagnóstico**; corregir código requiere encargo humano explícito y alcance delimitado. La skill **no garantiza** inspección visual automatizada ni sustituye pruebas, contraste medido o aprobación humana.

## Revisión focalizada (aplicar lo pertinente)

1. **Referencia:** identificar la maqueta/imagen histórica aprobada y la versión de Flutter en pantalla. Si falta la maqueta original, indicar `REFERENCIA_PARCIAL`, utilizar referencias confirmadas y **no atribuir una aprobación inexistente**.
2. **Jerarquía pedagógica:** el estudiante debe identificar situación, objetivo, acción principal y continuación sin desplazamientos innecesarios. La imagen ilustra; no oculta el acto de escuchar/hablar ni sustituye controles.
3. **Composición visual:** tamaños, márgenes, alineación, densidad, ancho de botones, consistencia de tarjetas, iconos y tipografía, estados visibles y acciones inequívocas. Reutilizar `MainShellScreen`, `LoguicTheme` y componentes existentes; no crear otra shell.
4. **Responsive:** revisar al menos escritorio amplio y ventana estrecha; considerar móvil si el alcance lo exige. Comprobar `overflow`, recortes, botones ocultos, desplazamiento, foco, legibilidad y orden de lectura. Una captura no prueba otros tamaños.
5. **Accesibilidad:** objetivo WCAG AA: contraste de texto normal >= 4.5:1 y texto grande >= 3:1 cuando aplique; comprobar etiquetas semánticas, navegación por teclado, foco visible, tamaños táctiles apropiados y estados accesibles. **No afirmar ratios de contraste sin medición**. Si no hay evidencia, marcar `PENDIENTE`.
6. **Disponibilidad real:** una función inacabada debe verse como `En preparación` y tener controles efectivamente deshabilitados. No simular progreso, pronunciación evaluada, dominio, aprendizaje ni servicios disponibles. Distinguir error de conexión de función inexistente.
7. **Regresiones y seguridad:** no modificar audio Kokoro, backend, datos de progreso, contratos curriculares, permisos, ni tracking si el alcance es solo UI. Preservar working trees sucios; no `reset`, `clean`, commits ni pushes no autorizados.
8. **Validar sin repetir:** aprovechar evidencia vigente de `flutter analyze`, tests enfocados y `git diff --check`; ejecutar solo verificaciones relacionadas con el cambio. Pruebas humanas de audios ya confirmadas no se repiten sin causa concreta.

## Resultado compacto obligatorio

- `PANTALLA / REFERENCIA`: pantalla, maqueta (o limitación de referencia).
- `HALLAZGOS`: hasta 5, cada uno con **severidad**, **evidencia**, **impacto** y **corrección mínima**.
- `VERIFICADO / PENDIENTE`: separar lo observado, lo probado y lo no probado.
- `ESTADO`: `REQUIERE_CORRECCION`, `LISTA_PARA_REVISION_HUMANA` o `BLOQUEADA`; **nunca APROBADA automáticamente**.
- `NEXT`: una acción verificable, sin iniciar otros incrementos.

## Piloto autorizado — Estación de tren

**Problema constatado en capturas humanas del 2026-11-16:** la imagen de la estación domina el área visible; la instrucción, reproducción y grabación quedan demasiado abajo; botones ocupan casi todo el ancho. Conservar ilustración y audios; evaluar tamaño máximo responsivo, agrupación de contexto e interacción, orden pedagógico y botones razonables. **Primera tarea: emitir revisión focalizada**. La implementación de ajustes queda sujeta a encargo delimitado y posterior Human Review Gate. Mantener el estado curricular MB1 como DRAFT; no activar.

## Reutilización

Una futura adopción transversal o cambio de gobernanza entre proyectos debe elevarse a **LOGUIC OS** antes de cambiar las autoridades compartidas; esta skill es de alcance local en LOGUIC English.
