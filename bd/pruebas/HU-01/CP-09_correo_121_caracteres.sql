/*
Archivo:     CP-09_correo_121_caracteres.sql
Historia:    HU-01
Escenario:   Correo de 121 caracteres (50007)
Propósito:   Un correo de 121 caracteres que termina en @empresa.com falla con 50007.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
/* 'cp09' + relleno + '@empresa.com' (12) = 121 */
DECLARE @correo nvarchar(400) = N'cp09' + REPLICATE(N'x', 121 - 4 - 12) + N'@empresa.com';
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
IF (LEN(@correo) <> 121)
BEGIN
    THROW 50900, N'FALLA CP-09: la prueba armó mal el correo', 1;
END;
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Larga', @Correo = @correo,
         @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50007) OR (@mensaje <> N'Dato inválido: Correo')
BEGIN
    THROW 50900, N'FALLA CP-09: se esperaba el error 50007 con su mensaje', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp09%')
BEGIN
    THROW 50900, N'FALLA CP-09: se insertó un empleado', 1;
END;

PRINT N'OK CP-09';
GO
