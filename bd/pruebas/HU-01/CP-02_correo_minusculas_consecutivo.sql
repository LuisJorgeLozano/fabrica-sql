/*
Archivo:     CP-02_correo_minusculas_consecutivo.sql
Historia:    HU-01
Escenario:   Correo en minúsculas y número consecutivo
Propósito:   El correo se guarda en minúsculas y el número crece de uno en uno.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Ventas');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
DECLARE @r1 TABLE (EmpleadoId int, NumeroEmpleado nvarchar(20));
DECLARE @r2 TABLE (EmpleadoId int, NumeroEmpleado nvarchar(20));
INSERT INTO @r1 (EmpleadoId, NumeroEmpleado)
EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Primero Cp02', @Correo = N'cp02.primero@empresa.com',
     @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
INSERT INTO @r2 (EmpleadoId, NumeroEmpleado)
EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Luis Gómez', @Correo = N'Cp02.Luis.Gomez@Empresa.com',
     @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
IF NOT EXISTS (
    SELECT 1
    FROM @r1 AS a
    CROSS JOIN @r2 AS b
    JOIN dbo.rh_Empleado AS e ON e.EmpleadoId = b.EmpleadoId
    WHERE (b.EmpleadoId = a.EmpleadoId + 1)
      AND (e.Correo COLLATE Latin1_General_BIN = N'cp02.luis.gomez@empresa.com')
      AND (b.NumeroEmpleado = N'EMP-' + RIGHT(N'0000' + CAST(a.EmpleadoId + 1 AS nvarchar(10)), 4))
)
BEGIN
    THROW 50900, N'FALLA CP-02: correo no minúsculas o número no consecutivo', 1;
END;

PRINT N'OK CP-02';
GO
