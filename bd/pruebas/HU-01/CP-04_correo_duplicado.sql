/*
Archivo:     CP-04_correo_duplicado.sql
Historia:    HU-01
Escenario:   Correo duplicado (50001)
Propósito:   Un correo repetido con otras mayúsculas falla con 50001 y no inserta nada.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez', @Correo = N'cp04.ana@empresa.com',
     @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;

DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Otra Ana', @Correo = N'CP04.ANA@empresa.com',
         @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50001) OR (@mensaje <> N'El correo ya está registrado')
BEGIN
    THROW 50900, N'FALLA CP-04: se esperaba el error 50001 con su mensaje', 1;
END;
IF ((SELECT COUNT(*) FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp04.%') <> 1)
BEGIN
    THROW 50900, N'FALLA CP-04: debía quedar un solo empleado', 1;
END;

PRINT N'OK CP-04';
GO
