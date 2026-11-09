/*
Archivo:     CP-06_fecha_ingreso_futura.sql
Historia:    HU-01
Escenario:   Fecha de ingreso futura (50003)
Propósito:   Una fecha de ingreso de mañana (UTC) falla con 50003.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @manana date = DATEADD(DAY, 1, CAST(SYSUTCDATETIME() AS date));
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Futura', @Correo = N'cp06.ana@empresa.com',
         @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @manana;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50003) OR (@mensaje <> N'La fecha de ingreso no puede ser futura')
BEGIN
    THROW 50900, N'FALLA CP-06: se esperaba el error 50003 con su mensaje', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp06.%')
BEGIN
    THROW 50900, N'FALLA CP-06: se insertó un empleado', 1;
END;

PRINT N'OK CP-06';
GO
