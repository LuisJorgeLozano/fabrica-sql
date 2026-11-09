/*
Archivo:     CP-05_correo_no_corporativo.sql
Historia:    HU-01
Escenario:   Correo no corporativo (50002)
Propósito:   Un correo fuera de @empresa.com falla con 50002.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Gmail', @Correo = N'cp05.ana@gmail.com',
         @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50002) OR (@mensaje <> N'Usa el correo corporativo @empresa.com')
BEGIN
    THROW 50900, N'FALLA CP-05: se esperaba el error 50002 con su mensaje', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp05.%')
BEGIN
    THROW 50900, N'FALLA CP-05: se insertó un empleado', 1;
END;

PRINT N'OK CP-05';
GO
