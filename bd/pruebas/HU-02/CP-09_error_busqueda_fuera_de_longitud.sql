/*
Archivo:     CP-09_error_busqueda_fuera_de_longitud.sql
Historia:    HU-02
Escenario:   Error, búsqueda fuera de longitud
Propósito:   Una búsqueda de 121 caracteres falla con 50007 «Dato inválido: Busqueda».
*/
SET NOCOUNT ON;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
DECLARE @texto nvarchar(400) = REPLICATE(N'a', 121);
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = @texto;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;

IF (@numeroError <> 50007)
BEGIN
    THROW 50900, N'FALLA CP-09: se esperaba el error 50007', 1;
END;
IF (@mensaje <> N'Dato inválido: Busqueda')
BEGIN
    THROW 50900, N'FALLA CP-09: el mensaje no coincide con el contrato', 1;
END;

PRINT N'OK CP-09';
GO
