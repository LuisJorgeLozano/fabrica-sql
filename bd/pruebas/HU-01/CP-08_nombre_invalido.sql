/*
Archivo:     CP-08_nombre_invalido.sql
Historia:    HU-01
Escenario:   Nombre corto o de 81 caracteres (50007)
Propósito:   Nombre de 1 o de 81 caracteres falla con 50007 y no se trunca ni se inserta.
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ayer date = DATEADD(DAY, -1, CAST(SYSUTCDATETIME() AS date));
DECLARE @nombreLargo nvarchar(200) = REPLICATE(N'N', 81);
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';

BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'A', @Correo = N'cp08.corto@empresa.com',
         @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50007) OR (@mensaje <> N'Dato inválido: Nombre')
BEGIN
    THROW 50900, N'FALLA CP-08: Nombre de 1 carácter debía dar 50007', 1;
END;

SET @numeroError = 0;
SET @mensaje = N'';
BEGIN TRY
    EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = @nombreLargo, @Correo = N'cp08.largo@empresa.com',
         @Puesto = N'Analista', @DepartamentoId = @dep, @FechaIngreso = @ayer;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;
IF (@numeroError <> 50007) OR (@mensaje <> N'Dato inválido: Nombre')
BEGIN
    THROW 50900, N'FALLA CP-08: Nombre de 81 caracteres debía dar 50007', 1;
END;
IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo LIKE N'cp08.%')
BEGIN
    THROW 50900, N'FALLA CP-08: se insertó un empleado', 1;
END;

PRINT N'OK CP-08';
GO
