/*
Archivo:     CP-01_listar_directorio_completo.sql
Historia:    HU-02
Escenario:   Listar el directorio completo
Propósito:   Sin parámetros devuelve a Ana (activo, Tecnología) y Luis (baja, Ventas) con sus
             columnas, y Ana aparece antes que Luis (orden por Nombre).
*/
SET NOCOUNT ON;

DECLARE @tec int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
DECLARE @ven int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Ventas');
CREATE TABLE #ign (EmpleadoId int, NumeroEmpleado nvarchar(20));

IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp01.ana@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez CP01', @Correo = N'cp01.ana@empresa.com',
        @Puesto = N'Analista', @DepartamentoId = @tec, @FechaIngreso = '2025-01-15';
END;
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp01.luis@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Luis Gómez CP01', @Correo = N'cp01.luis@empresa.com',
        @Puesto = N'Vendedor', @DepartamentoId = @ven, @FechaIngreso = '2025-01-15';
    UPDATE dbo.rh_Empleado SET Estado = N'baja', FechaBaja = '2025-06-01' WHERE Correo = N'cp01.luis@empresa.com';
END;

CREATE TABLE #r (Orden int IDENTITY(1, 1), EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80),
    Correo nvarchar(120), Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
INSERT INTO #r (EmpleadoId, NumeroEmpleado, Nombre, Correo, Puesto, DepartamentoId, Departamento, Estado)
EXEC dbo.rh_usp_EmpleadoConsultar;

IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp01.ana@empresa.com' AND Departamento = N'Tecnología'
               AND Estado = N'activo' AND Nombre = N'Ana Pérez CP01' AND Puesto = N'Analista'
               AND NumeroEmpleado LIKE N'EMP-%')
BEGIN
    THROW 50900, N'FALLA CP-01: falta Ana o sus datos son incorrectos', 1;
END;
IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp01.luis@empresa.com' AND Departamento = N'Ventas' AND Estado = N'baja')
BEGIN
    THROW 50900, N'FALLA CP-01: falta Luis o sus datos son incorrectos', 1;
END;
IF ((SELECT Orden FROM #r WHERE Correo = N'cp01.ana@empresa.com') > (SELECT Orden FROM #r WHERE Correo = N'cp01.luis@empresa.com'))
BEGIN
    THROW 50900, N'FALLA CP-01: no está ordenado por Nombre', 1;
END;
IF EXISTS (SELECT 1 FROM #r AS a INNER JOIN #r AS b ON b.Orden = a.Orden + 1 WHERE a.Nombre > b.Nombre COLLATE DATABASE_DEFAULT)
BEGIN
    /* Solo se compara si el orden binario difiere del collation: se valida con el propio ORDER BY */
    IF EXISTS (SELECT 1 FROM (SELECT Orden, ROW_NUMBER() OVER (ORDER BY Nombre, EmpleadoId) AS Esperado FROM #r) AS x WHERE x.Orden <> x.Esperado)
    BEGIN
        THROW 50900, N'FALLA CP-01: el orden del resultado no es por Nombre', 1;
    END;
END;

PRINT N'OK CP-01';
GO
