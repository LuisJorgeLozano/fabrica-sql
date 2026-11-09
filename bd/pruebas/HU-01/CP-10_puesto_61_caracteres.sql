/*
Archivo:     CP-10_puesto_61_caracteres.sql
Historia:    HU-01
Escenario:   Puesto de 61 caracteres (50007)
Propósito:   Un Puesto de 61 caracteres falla con 50007 sin truncarse.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
DECLARE @puesto nvarchar(200) = REPLICATE(N'P', 61);
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Puesto', @Correo = N'cp10.ana@empresa.com',
         @Puesto = @puesto, @DepartamentoId = @dep, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50007) OR (@mensaje <> N'Dato inválido: Puesto')
BEGIN
    THROW 50900, N'FALLA CP-10: se esperaba el error 50007 con su mensaje', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp10.%')
BEGIN
    THROW 50900, N'FALLA CP-10: se insertó un empleado', 1;
END;

PRINT N'OK CP-10';
GO
