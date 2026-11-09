/*
Archivo:     CP-11_catalogo_sin_duplicados.sql
Historia:    HU-01
Escenario:   Catálogo sin duplicados
Propósito:   Tras ejecutar los scripts (dos veces en el sandbox) hay exactamente 5 departamentos.
*/
SET NOCOUNT ON;

IF ((SELECT COUNT(*) FROM dbo.rh_Departamento AS d) <> 5)
BEGIN
    THROW 50900, N'FALLA CP-11: debe haber exactamente 5 departamentos', 1;
END;
IF ((SELECT COUNT(*) FROM dbo.rh_Departamento AS d
     WHERE d.Nombre IN (N'Tecnología', N'Ventas', N'Finanzas', N'Recursos Humanos', N'Operaciones')) <> 5)
BEGIN
    THROW 50900, N'FALLA CP-11: faltan departamentos iniciales', 1;
END;

PRINT N'OK CP-11';
GO
