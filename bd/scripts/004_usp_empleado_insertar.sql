/*
Archivo:     004_usp_empleado_insertar.sql
Historia:    HU-01
Propósito:   Procedimiento de alta de empleado. Valida sin truncar (parámetros más anchos que las
             columnas), guarda el correo en minúsculas y devuelve EmpleadoId y NumeroEmpleado.
*/
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.rh_usp_EmpleadoInsertar
    @Nombre         nvarchar(200)
  , @Correo         nvarchar(400)
  , @Puesto         nvarchar(200)
  , @DepartamentoId int
  , @FechaIngreso   date
/*
Ejemplo:  EXEC dbo.rh_usp_EmpleadoInsertar @Nombre = N'Ana Pérez', @Correo = N'ana.perez@empresa.com',
              @Puesto = N'Analista', @DepartamentoId = 1, @FechaIngreso = '2026-01-15';
*/
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* 1. Validar antes de tocar datos */
    SET @Nombre = LTRIM(RTRIM(@Nombre));
    SET @Correo = LOWER(LTRIM(RTRIM(@Correo)));
    SET @Puesto = LTRIM(RTRIM(@Puesto));

    IF (@Nombre IS NULL) OR (LEN(@Nombre) < 2) OR (LEN(@Nombre) > 80)
    BEGIN
        THROW 50007, N'Dato inválido: Nombre', 1;
    END;
    IF (@Correo IS NULL) OR (LEN(@Correo) = 0) OR (LEN(@Correo) > 120)
    BEGIN
        THROW 50007, N'Dato inválido: Correo', 1;
    END;
    IF (@Puesto IS NULL) OR (LEN(@Puesto) < 2) OR (LEN(@Puesto) > 60)
    BEGIN
        THROW 50007, N'Dato inválido: Puesto', 1;
    END;
    IF (@DepartamentoId IS NULL)
    BEGIN
        THROW 50007, N'Dato inválido: DepartamentoId', 1;
    END;
    IF (@FechaIngreso IS NULL)
    BEGIN
        THROW 50007, N'Dato inválido: FechaIngreso', 1;
    END;
    IF (@Correo NOT LIKE N'%@empresa.com')
    BEGIN
        THROW 50002, N'Usa el correo corporativo @empresa.com', 1;
    END;
    IF (@FechaIngreso > CAST(SYSUTCDATETIME() AS date))
    BEGIN
        THROW 50003, N'La fecha de ingreso no puede ser futura', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM dbo.rh_Departamento AS d WHERE d.DepartamentoId = @DepartamentoId)
    BEGIN
        THROW 50006, N'El departamento no existe', 1;
    END;
    IF EXISTS (SELECT 1 FROM dbo.rh_Empleado AS e WHERE LOWER(e.Correo) = @Correo)
    BEGIN
        THROW 50001, N'El correo ya está registrado', 1;
    END;

    /* 2. Modificar en una transacción corta */
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.rh_Empleado (Nombre, Correo, Puesto, DepartamentoId, FechaIngreso)
        VALUES (@Nombre, @Correo, @Puesto, @DepartamentoId, @FechaIngreso);

        SELECT e.EmpleadoId, e.NumeroEmpleado
        FROM dbo.rh_Empleado AS e
        WHERE e.EmpleadoId = CAST(SCOPE_IDENTITY() AS int);

        COMMIT TRANSACTION;
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
