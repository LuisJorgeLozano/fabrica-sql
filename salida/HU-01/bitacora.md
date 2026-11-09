# Bitácora HU-01 · /fabrica

**Estado final: LISTA**

## Pasos
1. Seguridad de la entrada: `jueces.entrada` → ENTRADA: OK.
2. Planificador (1.ª vez): plan de 9 escenarios; `jueces.validar` → válido.
3. Aprobación humana: la persona confirmó que «hoy» es UTC y pidió parámetros más anchos para el 50007 (rechazo 1 de 2). Nuevo plan: `jueces.validar` → FALLA por más de 70 líneas (81); se escaló a la persona.
2. (de nuevo) Con visto bueno de la persona se relanzó al planificador para resumir el plan y corregir el número de empleado (sin recorte pasado EMP-9999). `jueces.validar` → válido (11 escenarios, 4 tareas).
3. (de nuevo) La persona aprobó el plan («si, apruebo el plan»).
4. Implementador: 4 scripts; `jueces.sandbox sql` → VERIFICACIÓN: OK (dos vueltas sin error).
5. Tester: 11 pruebas; `jueces.sandbox pruebas HU-01` → 11 de 11 pasaron. Sin posibles defectos.
6. Revisor: `jueces.validar salida/HU-01/revision.json` → válido; `"aprobado": true` (0 altos, 1 medio, 2 bajos). Pruebas OK y aprobado → LISTA. No se relanzó al implementador, porque no hubo hallazgos altos.

## Hallazgos pendientes de la revisión (no bloquean)
- Media · `004_usp_empleado_insertar.sql`: el chequeo de correo duplicado está fuera de la transacción. Con dos altas simultáneas del mismo correo, la segunda falla con el error 2627 en vez de 50001. Propuesta: traducir 2601/2627 de `AK_rh_Empleado_Correo` a 50001 en el CATCH.
- Baja · `003_tabla_empleado.sql`: `CK_rh_Empleado_Correo` acepta «@empresa.com» sin parte local.
- Baja · `004_usp_empleado_insertar.sql`: el SELECT de salida va dentro de la transacción; conviene moverlo después del COMMIT.

## Scripts (bd/scripts/)
- `001_tabla_departamento.sql`
- `002_datos_departamento.sql`
- `003_tabla_empleado.sql`
- `004_usp_empleado_insertar.sql`

## Pruebas (bd/pruebas/HU-01/)
CP-01_alta_exitosa · CP-02_correo_minusculas_consecutivo · CP-03_numero_pasado_9999 · CP-04_correo_duplicado · CP-05_correo_no_corporativo · CP-06_fecha_ingreso_futura · CP-07_departamento_inexistente · CP-08_nombre_invalido · CP-09_correo_121_caracteres · CP-10_puesto_61_caracteres · CP-11_catalogo_sin_duplicados

## Límites
- CP-01 y CP-02 comparan contra el EmpleadoId devuelto, no contra los literales EMP-0001 y EMP-0002, porque el consecutivo depende del orden de las pruebas.
