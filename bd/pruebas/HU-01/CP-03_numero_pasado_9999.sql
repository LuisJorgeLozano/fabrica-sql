/*
Archivo:     CP-03_numero_pasado_9999.sql
Historia:    HU-01
Escenario:   Número pasado 9999
Propósito:   EmpleadoId 9999 da EMP-9999 y 10000 da EMP-10000 (sin recorte, sin chocar con la llave única).
*/
SET NOCOUNT ON;

DECLARE @dep int = (SELECT d.DepartamentoId FROM dbo.rh_Departamento AS d WHERE d.Nombre = N'Finanzas');
SET IDENTITY_INSERT dbo.rh_Empleado ON;
INSERT INTO dbo.rh_Empleado (EmpleadoId, Nombre, Correo, Puesto, DepartamentoId, FechaIngreso)
VALUES (9999, N'Cp03 Uno', N'cp03.uno@empresa.com', N'Analista', @dep, '2026-01-01'),
       (10000, N'Cp03 Dos', N'cp03.dos@empresa.com', N'Analista', @dep, '2026-01-01');
SET IDENTITY_INSERT dbo.rh_Empleado OFF;
IF NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE (e.EmpleadoId = 9999) AND (e.NumeroEmpleado = N'EMP-9999'))
   OR NOT EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE (e.EmpleadoId = 10000) AND (e.NumeroEmpleado = N'EMP-10000'))
BEGIN
    THROW 50900, N'FALLA CP-03: el número no es EMP-9999 / EMP-10000', 1;
END;

PRINT N'OK CP-03';
GO
