# Bitácora HU-02 · Consultar el directorio de empleados

**Estado final: LISTA**

## Pasos
1. Seguridad de la entrada: `jueces.entrada` → ENTRADA: OK.
2. Planificador: plan escrito; `jueces.validar` → válido (9 escenarios, 2 tareas).
3. Aprobación humana: aprobado por adelantado (`--aprobar`).
4. Implementador: `jueces.sandbox sql` → OK (6 scripts, 2 vueltas sin error).
5. Tester: `jueces.sandbox pruebas HU-02` → 9 de 9 pruebas OK.
6. Revisor: `revision.json` válido, `"aprobado": true` (0 altas, 1 media, 2 bajas). No se necesitó segunda vuelta del implementador.
7. Bitácora escrita.

## Hallazgos pendientes (no bloquean)
- Media: `@Busqueda` es `nvarchar(400)` en el script y `nvarchar(120)` en el plan. La desviación es intencional (evita truncar en silencio y permite el 50007); falta ajustar el plan.
- Baja: `TRY/CATCH` sin transacción en un procedimiento de solo lectura (lo exige CNV-5); el cuerpo del `TRY` no está indentado.
- Baja: `LOWER(...) LIKE '%...%'` no usa índices; revisar si el directorio crece.

## Preguntas abiertas del plan (sin respuesta de la persona)
- Escapar `%`, `_` y `[` como texto literal: el implementador aplicó la propuesta.
- Ocultar empleados dados de baja: no se hace, se incluyen todos.
- Paginación: se omite.

## Scripts
- bd/scripts/005_vista_directorio.sql
- bd/scripts/006_usp_empleado_consultar.sql

## Pruebas (bd/pruebas/HU-02/)
- CP-01_listar_directorio_completo.sql
- CP-02_buscar_por_nombre.sql
- CP-03_buscar_por_correo.sql
- CP-04_filtrar_por_departamento.sql
- CP-05_busqueda_y_departamento.sql
- CP-06_sin_resultados.sql
- CP-07_empleado_de_baja_en_directorio.sql
- CP-08_error_departamento_inexistente.sql
- CP-09_error_busqueda_fuera_de_longitud.sql
