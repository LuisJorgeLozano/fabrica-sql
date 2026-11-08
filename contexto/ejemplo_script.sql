/*
Archivo:     ejemplo_script.sql
Historia:    (ejemplo de referencia, no se ejecuta)
Propósito:   Tabla con restricciones nombradas, datos iniciales y un procedimiento de alta,
             todo idempotente. Copia esta forma.
*/
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.rh_Sede', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.rh_Sede
    (
        SedeId      int IDENTITY(1, 1) NOT NULL
      , Nombre      nvarchar(50)       NOT NULL
      , CreadoEn    datetime2(0)       NOT NULL CONSTRAINT DF_rh_Sede_CreadoEn DEFAULT (SYSUTCDATETIME())
      , CONSTRAINT PK_rh_SedeID PRIMARY KEY CLUSTERED (SedeId)
      , CONSTRAINT AK_rh_Sede_Nombre UNIQUE (Nombre)
      , CONSTRAINT CK_rh_Sede_Nombre CHECK (LEN(Nombre) >= 2)
    );
END;
GO

INSERT INTO dbo.rh_Sede (Nombre)
SELECT v.Nombre
FROM (VALUES (N'Norte'), (N'Occidente')) AS v (Nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.rh_Sede AS s WHERE s.Nombre = v.Nombre);
GO

CREATE OR ALTER PROCEDURE dbo.rh_usp_SedeInsertar
    @nombre nvarchar(50)
  , @sedeId int OUTPUT
/*
Ejemplo:  DECLARE @id int; EXEC dbo.rh_usp_SedeInsertar @nombre = N'Centro', @sedeId = @id OUTPUT;
*/
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* 1. Validar antes de tocar datos */
    SET @nombre = LTRIM(RTRIM(@nombre));
    IF (@nombre IS NULL) OR (LEN(@nombre) < 2)
    BEGIN
        THROW 50007, N'Dato inválido: nombre', 1;
    END;
    IF EXISTS (SELECT 1 FROM dbo.rh_Sede AS s WHERE s.Nombre = @nombre)
    BEGIN
        THROW 50009, N'La sede ya está registrada', 1;
    END;

    /* 2. Modificar en una transacción corta */
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO dbo.rh_Sede (Nombre) VALUES (@nombre);
        SET @sedeId = CAST(SCOPE_IDENTITY() AS int);
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