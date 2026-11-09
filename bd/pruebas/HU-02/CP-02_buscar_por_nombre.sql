/*
Archivo:     CP-02_buscar_por_nombre.sql
Historia:    HU-02
Escenario:   Buscar por nombre sin importar mayúsculas
Propósito:   @Busqueda = N'ANA pé' encuentra a Ana Pérez.
*/
SET NOCOUNT ON;

DECLARE @tec int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
CREATE TABLE #ign (EmpleadoId int, NumeroEmpleado nvarchar(20));
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp02.ana@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez', @Correo = N'cp02.ana@empresa.com',
        @Puesto = N'Analista', @DepartamentoId = @tec, @FechaIngreso = '2025-01-15';
END;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = N'ANA pé';

IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp02.ana@empresa.com' AND Nombre = N'Ana Pérez')
BEGIN
    THROW 50900, N'FALLA CP-02: no encontró a Ana Pérez', 1;
END;

PRINT N'OK CP-02';
GO
