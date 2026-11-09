/*
Archivo:     CP-06_sin_resultados.sql
Historia:    HU-02
Escenario:   Sin resultados
Propósito:   Una búsqueda sin coincidencias devuelve un conjunto vacío con las 8 columnas y sin error.
*/
SET NOCOUNT ON;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
DECLARE @numeroError int = 0;
BEGIN TRY
    INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = N'zzzz';
END TRY
BEGIN CATCH
    SET @numeroError = ERROR_NUMBER();
END CATCH;

IF (@numeroError <> 0)
BEGIN
    THROW 50900, N'FALLA CP-06: la consulta sin resultados produjo error', 1;
END;
IF EXISTS (SELECT 1 FROM #r)
BEGIN
    THROW 50900, N'FALLA CP-06: se esperaba un conjunto vacío', 1;
END;

PRINT N'OK CP-06';
GO
