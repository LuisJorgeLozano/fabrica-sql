/*
Archivo:     CP-05_busqueda_y_departamento.sql
Historia:    HU-02
Escenario:   Búsqueda y departamento combinados
Propósito:   Con @Busqueda = N'ana' y Ventas devuelve a Ana Ruiz y no a Ana Pérez (Tecnología).
*/
SET NOCOUNT ON;

DECLARE @tec int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ven int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Ventas');
CREATE TABLE #ign (EmpleadoId int, NumeroEmpleado nvarchar(20));
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp05.perez@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez CP05', @Correo = N'cp05.perez@empresa.com',
        @Puesto = N'Analista', @DepartamentoId = @tec, @FechaIngreso = '2025-01-15';
END;
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp05.ruiz@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Ruiz CP05', @Correo = N'cp05.ruiz@empresa.com',
        @Puesto = N'Vendedora', @DepartamentoId = @ven, @FechaIngreso = '2025-01-15';
END;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = N'ana', @DepartamentoId = @ven;

IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp05.ruiz@empresa.com')
BEGIN
    THROW 50900, N'FALLA CP-05: falta Ana Ruiz', 1;
END;
IF EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp05.perez@empresa.com')
BEGIN
    THROW 50900, N'FALLA CP-05: apareció Ana Pérez de Tecnología', 1;
END;
IF EXISTS (SELECT 1 FROM #r WHERE DepartamentoId <> @ven)
BEGIN
    THROW 50900, N'FALLA CP-05: aparecen empleados de otro departamento', 1;
END;

PRINT N'OK CP-05';
GO
