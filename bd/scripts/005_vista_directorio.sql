/*
Archivo:     005_vista_directorio.sql
Historia:    HU-02
Propósito:   Vista del directorio de empleados con el nombre del departamento. Idempotente
             (CREATE OR ALTER).
*/
SET NOCOUNT ON;
GO

CREATE OR ALTER VIEW dbo.rh_VI_Directorio
AS
SELECT e.EmpleadoId
     , e.NumeroEmpleado
     , e.Nombre
     , e.Correo
     , e.Puesto
     , e.DepartamentoId
     , d.Nombre AS Departamento
     , e.Estado
FROM dbo.rh_Empleado AS e
INNER JOIN dbo.rh_Departamento AS d
    ON d.DepartamentoId = e.DepartamentoId;
GO
