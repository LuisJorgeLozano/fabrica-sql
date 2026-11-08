/*
Archivo:     CP-00_ejemplo.sql
Historia:    (ejemplo de referencia, no se ejecuta)
Escenario:   Alta de sede y rechazo de sede duplicada
Propósito:   Una comprobación de éxito y una de error esperado. Si algo no se cumple,
             THROW 50900 detiene sqlcmd y el sandbox marca la prueba como FALLA.
*/
SET NOCOUNT ON;

/* Éxito: la fila existe con los datos enviados */
DECLARE @id int;
EXEC dbo.rh_usp_SedeInsertar @nombre = N'Sede CP-00', @sedeId = @id OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Sede AS s WHERE (s.SedeId = @id) AND (s.Nombre = N'Sede CP-00'))
BEGIN
    THROW 50900, N'FALLA CP-00: la sede no quedó registrada', 1;
END;
GO

/* Error esperado: el duplicado falla con el error de negocio 50009 */
DECLARE @id int;
DECLARE @numeroError int = 0;
BEGIN TRY
    EXEC dbo.rh_usp_SedeInsertar @nombre = N'Sede CP-00', @sedeId = @id OUTPUT;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
END CATCH;
IF (@numeroError <> 50009)
BEGIN
    THROW 50900, N'FALLA CP-00: se esperaba el error 50009', 1;
END;

PRINT N'OK CP-00';
GO