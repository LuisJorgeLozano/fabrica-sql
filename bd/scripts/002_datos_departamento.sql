/*
Archivo:     002_datos_departamento.sql
Historia:    HU-01
Propósito:   Carga los 5 departamentos iniciales sin duplicarlos. Idempotente.
*/
SET NOCOUNT ON;

INSERT INTO dbo.rh_Departamento (Nombre)
SELECT v.Nombre
FROM (VALUES (N'Tecnología'), (N'Ventas'), (N'Finanzas'), (N'Recursos Humanos'), (N'Operaciones')) AS v (Nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.rh_Departamento AS d WHERE d.Nombre = v.Nombre);
GO
