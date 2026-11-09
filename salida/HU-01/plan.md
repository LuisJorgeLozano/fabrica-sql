# Plan HU-01 · Registrar empleado
Comentarios incorporados: «hoy» es UTC; parámetros más anchos que las columnas (50007); plan resumido a menos de 70 líneas; número EMP sin recorte pasado 9999.

## Criterios de aceptación
- Escenario: Alta exitosa
  - Dado el departamento «Tecnología» existente y `ana.perez@empresa.com` sin registrar
  - Cuando se ejecuta dbo.rh_usp_EmpleadoInsertar con Nombre «Ana Pérez», Puesto «Analista», ingreso de ayer (UTC)
  - Entonces devuelve EmpleadoId y NumeroEmpleado EMP-0001, con Estado «activo» y FechaBaja NULL
- Escenario: Correo en minúsculas y número consecutivo
  - Dado EMP-0001 registrado y el correo `Luis.Gomez@Empresa.com`
  - Cuando se registra otro empleado válido
  - Entonces recibe EMP-0002 y el Correo guardado es `luis.gomez@empresa.com`
- Escenario: Número pasado 9999
  - Dado un empleado con EmpleadoId 9999 (EMP-9999) y otro con EmpleadoId 10000
  - Cuando se consulta NumeroEmpleado
  - Entonces es EMP-10000 (sin recorte), distinto de EMP-0000 y sin chocar con la llave única
- Escenario: Correo duplicado (50001)
  - Dado `ana.perez@empresa.com` ya registrado
  - Cuando se registra `ANA.PEREZ@empresa.com`
  - Entonces falla con 50001 «El correo ya está registrado» y no se inserta nada
- Escenario: Correo no corporativo (50002)
  - Dado el correo `ana@gmail.com`
  - Cuando se registra al empleado
  - Entonces falla con 50002 «Usa el correo corporativo @empresa.com»
- Escenario: Fecha de ingreso futura (50003)
  - Dado una fecha de ingreso de mañana (UTC)
  - Cuando se registra al empleado
  - Entonces falla con 50003 «La fecha de ingreso no puede ser futura»
- Escenario: Departamento inexistente (50006)
  - Dado el DepartamentoId 9999 que no existe
  - Cuando se registra al empleado
  - Entonces falla con 50006 «El departamento no existe»
- Escenario: Nombre corto o de 81 caracteres (50007)
  - Dado un Nombre de 1 carácter («A») o de 81 caracteres
  - Cuando se registra al empleado
  - Entonces falla con 50007 «Dato inválido: Nombre» y no se trunca ni se inserta
- Escenario: Correo de 121 caracteres (50007)
  - Dado un Correo de 121 caracteres que termina en @empresa.com
  - Cuando se registra al empleado
  - Entonces falla con 50007 «Dato inválido: Correo»
- Escenario: Puesto de 61 caracteres (50007)
  - Dado un Puesto de 61 caracteres
  - Cuando se registra al empleado
  - Entonces falla con 50007 «Dato inválido: Puesto»
- Escenario: Catálogo sin duplicados
  - Dado el script de departamentos ejecutado dos veces
  - Cuando se consulta dbo.rh_Departamento
  - Entonces hay exactamente 5 departamentos

## Tablas
- dbo.rh_Departamento: DepartamentoId int IDENTITY NOT NULL, Nombre nvarchar(50) NOT NULL; PK_rh_DepartamentoID, AK_rh_Departamento_Nombre.
- dbo.rh_Empleado:
  - EmpleadoId int IDENTITY NOT NULL, PK_rh_EmpleadoID; NumeroEmpleado calculada persistida `N'EMP-' + CASE WHEN EmpleadoId < 10000 THEN RIGHT(N'0000' + CAST(EmpleadoId AS nvarchar(10)), 4) ELSE CAST(EmpleadoId AS nvarchar(10)) END` (mínimo 4 dígitos, sin recorte), AK_rh_Empleado_NumeroEmpleado.
  - Nombre nvarchar(80) NOT NULL, CK_rh_Empleado_Nombre (LEN 2 a 80); Puesto nvarchar(60) NOT NULL, CK_rh_Empleado_Puesto (LEN 2 a 60).
  - Correo nvarchar(120) NOT NULL, AK_rh_Empleado_Correo, CK_rh_Empleado_Correo (termina en @empresa.com).
  - DepartamentoId int NOT NULL, FK_rh_Empleado_rh_DepartamentoID; FechaIngreso date NOT NULL.
  - Estado nvarchar(10) NOT NULL, DF_rh_Empleado_Estado = N'activo', CK_rh_Empleado_Estado (activo o baja).
  - FechaBaja date NULL, CK_rh_Empleado_FechaBaja (solo con «baja» y no anterior a FechaIngreso).
  - CreadoEn datetime2(0) NOT NULL, DF_rh_Empleado_CreadoEn = SYSUTCDATETIME(); IX_rh_Empleado_DepartamentoId.

## Procedimientos
- dbo.rh_usp_EmpleadoInsertar(@Nombre nvarchar(200), @Correo nvarchar(400), @Puesto nvarchar(200), @DepartamentoId int, @FechaIngreso date)
  - Valida con LEN sin truncar: Nombre (vacío, <2, >80), Correo (vacío, >120), Puesto (vacío, <2, >60), DepartamentoId o FechaIngreso nulos: 50007 con el campo; sin @empresa.com 50002; fecha > CAST(SYSUTCDATETIME() AS date) 50003; departamento inexistente 50006; correo duplicado sin importar mayúsculas 50001.
  - Inserta el correo en minúsculas en transacción explícita (TRY/CATCH, ROLLBACK, THROW;) y devuelve EmpleadoId y NumeroEmpleado.

## Tareas
- 001_tabla_departamento.sql: crea dbo.rh_Departamento con PK y AK, idempotente.
- 002_datos_departamento.sql: carga los 5 departamentos con WHERE NOT EXISTS.
- 003_tabla_empleado.sql: crea dbo.rh_Empleado con restricciones, FK, NumeroEmpleado sin recorte e índice, idempotente.
- 004_usp_empleado_insertar.sql: CREATE OR ALTER dbo.rh_usp_EmpleadoInsertar con parámetros anchos.
