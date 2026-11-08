# Convenciones de los scripts de SQL Server

Base: «SQL Server Name Convention and T-SQL Programming Style» (ktaranov/sqlserver-kit) + reglas del equipo.
Las reglas con código (`CNV-x`, `SEG-x`) las revisa `jueces/sql.py`: si no se cumplen, la compuerta devuelve el trabajo.

## Nombres (CNV-1, CNV-2)

La clave de la aplicación es `rh` (2 a 5 letras minúsculas). Va al inicio de tablas, vistas y procedimientos.

| Objeto | Formato | Ejemplo |
| --- | --- | --- |
| Tabla (singular) | `dbo.rh_NombrePascal` | `dbo.rh_Empleado` |
| Vista | `dbo.rh_VI_Nombre` | `dbo.rh_VI_Directorio` |
| Procedimiento | `dbo.rh_usp_Nombre` | `dbo.rh_usp_EmpleadoInsertar` |
| Columna | PascalCase | `FechaIngreso` |
| Llave primaria / foránea / única | `PK_<Tabla>ID` / `FK_<Tabla>_<Referida>ID` / `AK_<Tabla>_<Columna>` | `PK_rh_EmpleadoID` |
| Check / default | `CK_<Tabla>_<Columna>` / `DF_<Tabla>_<Columna>` | `DF_rh_Empleado_CreadoEn` |
| Índice | `IX_<Tabla>_<Columnas>` | `IX_rh_Empleado_DepartamentoId` |

Todas las restricciones llevan nombre (`CONSTRAINT <nombre> ...`).

## Estilo

- Palabras clave en MAYÚSCULAS; tipos en minúsculas y con longitud (`nvarchar(80)`); textos con `N'...'`.
- Nunca `SELECT *` (CNV-4); siempre lista de columnas en `INSERT`.
- Comentarios con `/* */`. Cada instrucción termina con `;`.
- Alias con `AS`, `JOIN` explícitos, paréntesis cuando hay más de un `AND`/`OR`.

## Idempotencia (CNV-3)

Cada script se puede correr varias veces sin error: `IF OBJECT_ID(N'dbo.rh_X', N'U') IS NULL` antes de
`CREATE TABLE`; `CREATE OR ALTER` en vistas y procedimientos; datos de catálogo con `WHERE NOT EXISTS`.
El sandbox ejecuta todos los scripts dos veces para comprobarlo.

## Procedimientos (CNV-5)

`SET NOCOUNT ON;` y `SET XACT_ABORT ON;`, validación de parámetros con `THROW <número>, N'<mensaje>', 1;`
(números y mensajes de `contexto/reglas_negocio.md`), y la modificación dentro de `BEGIN TRY` /
`BEGIN CATCH` con transacción explícita; en el `CATCH`: `ROLLBACK` si hay transacción y `THROW;`.

## Archivos (CNV-6)

- Scripts en `bd/scripts/`, numerados en orden de ejecución: `001_tabla_departamento.sql`, `002_...`
  Si ya hay scripts de otras historias, se continúa la numeración.
- Pruebas en `bd/pruebas/HU-xx/`: `CP-01_alta_exitosa.sql`, una por escenario como mínimo.
- Todo archivo empieza con un encabezado `/* Archivo, Historia, Propósito */` y termina con `GO`.

## Prohibido en cualquier script o prueba (SEG)

| Código | Prohibido |
| --- | --- |
| SEG-1 | `xp_*`, `sp_configure`, `RECONFIGURE`, `OPENROWSET`, `OPENDATASOURCE`, `BULK INSERT` |
| SEG-2 | `CREATE/ALTER/DROP DATABASE`, `USE`, `BACKUP`, `RESTORE`, `SHUTDOWN` |
| SEG-3 | `CREATE/ALTER/DROP LOGIN/USER/ROLE`, `GRANT`, `DENY`, `REVOKE`, `EXECUTE AS` |
| SEG-4 | SQL dinámico: `EXEC (...)`, `EXEC @variable`, `sp_executesql` |
| SEG-5 | `DROP TABLE/VIEW/PROCEDURE/FUNCTION`, `TRUNCATE TABLE` |

Los logins, permisos y cambios al servidor los hace el DBA, nunca un script generado.

## Pruebas

T-SQL puro, como `contexto/ejemplo_prueba.sql`: el éxito se comprueba con `IF NOT EXISTS (...) THROW 50900, ...`;
el error esperado con `TRY/CATCH` y `ERROR_NUMBER()` comparado con el número de las reglas de negocio.
Datos únicos por prueba (por ejemplo `cp01.ana@empresa.com`). Termina con `PRINT N'OK CP-xx';` y `GO`.