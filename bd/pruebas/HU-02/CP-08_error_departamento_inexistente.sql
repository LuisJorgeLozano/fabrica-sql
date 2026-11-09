/*
Archivo:     CP-08_error_departamento_inexistente.sql
Historia:    HU-02
Escenario:   Error, departamento inexistente
Propósito:   @DepartamentoId = 99999 falla con 50006 «El departamento no existe».
*/
SET NOCOUNT ON;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
DECLARE @numeroError int = 0;
DECLARE @mensaje nvarchar(2048) = N'';
BEGIN TRY
    INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @DepartamentoId = 99999;
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
    SET @mensaje = ERROR_MESSAGE();
END CATCH;

IF (@numeroError <> 50006)
BEGIN
    THROW 50900, N'FALLA CP-08: se esperaba el error 50006', 1;
END;
IF (@mensaje <> N'El departamento no existe')
BEGIN
    THROW 50900, N'FALLA CP-08: el mensaje no coincide con el contrato', 1;
END;

PRINT N'OK CP-08';
GO
