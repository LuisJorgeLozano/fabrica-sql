/*
Archivo:     CP-03_buscar_por_correo.sql
Historia:    HU-02
Escenario:   Buscar por correo sin importar mayúsculas
Propósito:   @Busqueda = N'ANA.CP03@EMPRESA' encuentra al empleado con ese correo.
*/
SET NOCOUNT ON;

DECLARE @tec int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Tecnología');
CREATE TABLE #ign (EmpleadoId int, NumeroEmpleado nvarchar(20));
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE e.Correo = N'ana.cp03@empresa.com')
BEGIN
    INSERT INTO #ign EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez CP03', @Correo = N'ana.cp03@empresa.com',
        @Puesto = N'Analista', @DepartamentoId = @tec, @FechaIngreso = '2025-01-15';
END;

CREATE TABLE #r (EmpleadoId int, NumeroEmpleado nvarchar(20), Nombre nvarchar(80), Correo nvarchar(120),
    Puesto nvarchar(60), DepartamentoId int, Departamento nvarchar(50), Estado nvarchar(10));
INSERT INTO #r EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = N'ANA.CP03@EMPRESA';

IF NOT EXISTS (SELECT 1 FROM #r WHERE Correo = N'ana.cp03@empresa.com')
BEGIN
    THROW 50900, N'FALLA CP-03: no encontró al empleado por correo', 1;
END;

PRINT N'OK CP-03';
GO
