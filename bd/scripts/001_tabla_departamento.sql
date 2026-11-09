/*
Archivo:     001_tabla_departamento.sql
Historia:    HU-01
Propósito:   Crea el catálogo dbo.rh_Departamento con llave primaria y nombre único. Idempotente.
*/
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.rh_Departamento', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.rh_Departamento
    (
        DepartamentoId int IDENTITY(1, 1) NOT NULL
      , Nombre         nvarchar(50)       NOT NULL
      , CONSTRAINT PK_rh_DepartamentoID PRIMARY KEY CLUSTERED (DepartamentoId)
      , CONSTRAINT AK_rh_Departamento_Nombre UNIQUE (Nombre)
    );
END;
GO
