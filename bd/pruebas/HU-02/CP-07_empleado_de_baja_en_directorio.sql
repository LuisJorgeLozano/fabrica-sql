/*
Archivo:     CP-07_empleado_de_baja_en_directorio.sql
Historia:    HU-02
Escenario:   Los empleados dados de baja siguen en el directorio
Propósito:   Luis con Estado = «baja» aparece al buscar N'luis' con Estado = «baja».
*/
SET NOCOUNT ON;

DECLARE @ven int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Ventas');
CREATE TABLE #ign (EmpleadoId int, NumeroEmpleado nvarchar(20));
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'cp07.luis@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Luis Gómez CP07', @Correo = N'cp07.luis@empresa.com',
        @Puesto = N'Vendedor', @DepartamentoId = @ven, @FechaIngreso = '2025-01-15';
    UPDATE dbo.rh_Empleado SET Estado = N'baja', FechaBaja = '2025-06-01' WHERE Correo = N'cp07.luis@empresa.com';
END;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = N'luis';

IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'cp07.luis@empresa.com' AND Estado = N'baja')
BEGIN
    THROW 50900, N'FALLA CP-07: el empleado de baja no aparece con Estado baja', 1;
END;

PRINT N'OK CP-07';
GO
