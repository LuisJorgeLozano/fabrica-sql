/*
Archivo:     CP-04_filtrar_por_departamento.sql
Historia:    HU-02
Escenario:   Filtrar por departamento
Propósito:   Con @DepartamentoId de Ventas solo salen empleados de Ventas.
*/
SET NOCOUNT ON;

DECLARE @tec int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ven int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Ventas');
CREATE TABLE #ign (EmpleadoId int, NumeroEmpleado nvarchar(20));
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp04.tec@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Teresa CP04', @Correo = N'cp04.tec@empresa.com',
        @Puesto = N'Analista', @DepartamentoId = @tec, @FechaIngreso = '2025-01-15';
END;
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp04.ven@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Victor CP04', @Correo = N'cp04.ven@empresa.com',
        @Puesto = N'Vendedor', @DepartamentoId = @ven, @FechaIngreso = '2025-01-15';
END;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @DepartamentoId = @ven;

IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp04.ven@empresa.com')
BEGIN
    THROW 50900, N'FALLA CP-04: falta el empleado de Ventas', 1;
END;
IF EXISTS (SELECT 1 FROM #r WHERE DepartamentoId <> @ven)
BEGIN
    THROW 50900, N'FALLA CP-04: aparecen empleados de otro departamento', 1;
END;

PRINT N'OK CP-04';
GO
