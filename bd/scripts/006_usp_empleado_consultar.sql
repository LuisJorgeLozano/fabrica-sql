/*
Archivo:     006_usp_empleado_consultar.sql
Historia:    HU-02
Propósito:   Consulta del directorio con búsqueda opcional por nombre o correo (sin distinguir
             mayúsculas, % y _ literales) y filtro opcional por departamento. Solo lectura.
*/
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.rh_usp_EmpleadoConsultar
    @Busqueda       nvarchar(400) = NULL
  , @DepartamentoId int           = NULL
/*
Ejemplo:  EXEC dbo.rh_usp_EmpleadoConsultar @Busqueda = N'ana', @DepartamentoId = 1;
*/
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* 1. Validar parámetros */
    SET @Busqueda = LTRIM(RTRIM(@Busqueda));
    IF (LEN(@Busqueda) > 120)
    BEGIN
        THROW 50007, N'Dato inválido: Busqueda', 1;
    END;
    IF (@DepartamentoId IS NOT NULL)
       AND NOT EXISTS (SELECT 1 FROM dbo.rh_Departamento AS d WHERE d.DepartamentoId = @DepartamentoId)
    BEGIN
        THROW 50006, N'El departamento no existe', 1;
    END;

    /* 2. Patrón de búsqueda con comodines escapados */
    DECLARE @Patron nvarchar(500) = NULL;
    IF (@Busqueda IS NOT NULL) AND (LEN(@Busqueda) > 0)
    BEGIN
        SET @Patron = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(LOWER(@Busqueda)
                          , N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[') + N'%';
    END;

    /* 3. Consultar (solo lectura, sin transacción) */
    BEGIN TRY
    SELECT v.EmpleadoId
         , v.NumeroEmpleado
         , v.Nombre
         , v.Correo
         , v.Puesto
         , v.DepartamentoId
         , v.Departamento
         , v.Estado
    FROM dbo.rh_VI_Directorio AS v
    WHERE ((@DepartamentoId IS NULL) OR (v.DepartamentoId = @DepartamentoId))
      AND ((@Patron IS NULL)
           OR (LOWER(v.Nombre) LIKE @Patron ESCAPE N'\')
           OR (LOWER(v.Correo) LIKE @Patron ESCAPE N'\'))
    ORDER BY v.Nombre, v.EmpleadoId;
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION;
        END;
        THROW;
    END CATCH;
END;
GO
