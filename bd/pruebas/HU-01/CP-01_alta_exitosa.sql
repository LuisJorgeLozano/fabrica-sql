/*
Archivo:     CP-01_alta_exitosa.sql
Historia:    HU-01
Escenario:   Alta exitosa
Propósito:   Alta válida: devuelve EmpleadoId y NumeroEmpleado, estado activo y sin FechaBaja.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
DECLARE @r TABLE (EmpleadoId int, NumeroEmpleado nvarchar(20));
INSERT INTO @r (EmpleadoId, NumeroEmpleado)
EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez', @Correo = N'cp01.ana@empresa.com',
     @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
IF NOT EXISTS (
    SELECT 1
    FROM @r AS r
    JOIN dbo.rh_Empleado AS e ON e.EmpleadoId = r.EmpleadoId
    WHERE (e.Correo = N'cp01.ana@empresa.com') AND (e.Estado = N'activo') AND (e.FechaBaja IS NULL)
      AND (e.Nombre = N'Ana Pérez') AND (e.DepartamentoId = @dep) AND (e.FechaIngreso = @ayer)
      AND (r.NumeroEmpleado = e.NumeroEmpleado)
      AND (e.NumeroEmpleado = N'EMP-' + RIGHT(N'0000' + CAST(e.EmpleadoId AS nvarchar(10)), 4))
)
BEGIN
    THROW 50900, N'FALLA CP-01: el alta no quedó como se esperaba', 1;
END;

PRINT N'OK CP-01';
GO
