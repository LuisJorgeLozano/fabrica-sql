/*
Archivo:     CP-07_departamento_inexistente.sql
Historia:    HU-01
Escenario:   Departamento inexistente (50006)
Propósito:   Un DepartamentoId que no existe falla con 50006.
*/
SET NOCOUNT ON;

DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Sin Depto', @Correo = N'cp07.ana@empresa.com',
         @Puesto = N'Analista', @DepartamentoId = 9999, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50006) OR (@mensaje <> N'El departamento no existe')
BEGIN
    THROW 50900, N'FALLA CP-07: se esperaba el error 50006 con su mensaje', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp07.%')
BEGIN
    THROW 50900, N'FALLA CP-07: se insertó un empleado', 1;
END;

PRINT N'OK CP-07';
GO
