/*
Archivo:     003_tabla_empleado.sql
Historia:    HU-01
Propósito:   Crea dbo.rh_Empleado con restricciones nombradas, número de empleado calculado
             (mínimo 4 dígitos, sin recorte), llave foránea e índice. Idempotente.
*/
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.rh_Empleado', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.rh_Empleado
    (
        EmpleadoId     int IDENTITY(1, 1) NOT NULL
      , NumeroEmpleado AS (N'EMP-' + CASE WHEN EmpleadoId < 10000
                                          THEN RIGHT(N'0000' + CAST(EmpleadoId AS nvarchar(10)), 4)
                                          ELSE CAST(EmpleadoId AS nvarchar(10)) END) PERSISTED
      , Nombre         nvarchar(80)       NOT NULL
      , Correo         nvarchar(120)      NOT NULL
      , Puesto         nvarchar(60)       NOT NULL
      , DepartamentoId int                NOT NULL
      , FechaIngreso   date               NOT NULL
      , Estado         nvarchar(10)       NOT NULL CONSTRAINT DF_rh_Empleado_Estado DEFAULT (N'activo')
      , FechaBaja      date               NULL
      , CreadoEn       datetime2(0)       NOT NULL CONSTRAINT DF_rh_Empleado_CreadoEn DEFAULT (SYSUTCDATETIME())
      , CONSTRAINT PK_rh_EmpleadoID PRIMARY KEY CLUSTERED (EmpleadoId)
      , CONSTRAINT AK_rh_Empleado_NumeroEmpleado UNIQUE (NumeroEmpleado)
      , CONSTRAINT AK_rh_Empleado_Correo UNIQUE (Correo)
      , CONSTRAINT FK_rh_Empleado_rh_DepartamentoID FOREIGN KEY (DepartamentoId)
            REFERENCES dbo.rh_Departamento (DepartamentoId)
      , CONSTRAINT CK_rh_Empleado_Nombre CHECK (LEN(Nombre) BETWEEN 2 AND 80)
      , CONSTRAINT CK_rh_Empleado_Puesto CHECK (LEN(Puesto) BETWEEN 2 AND 60)
      , CONSTRAINT CK_rh_Empleado_Correo CHECK (Correo LIKE N'%@empresa.com')
      , CONSTRAINT CK_rh_Empleado_Estado CHECK (Estado IN (N'activo', N'baja'))
      , CONSTRAINT CK_rh_Empleado_FechaBaja CHECK
            (
                (FechaBaja IS NULL AND Estado = N'activo')
                OR (FechaBaja IS NOT NULL AND Estado = N'baja' AND FechaBaja >= FechaIngreso)
            )
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_rh_Empleado_DepartamentoId' AND object_id = OBJECT_ID(N'dbo.rh_Empleado'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_rh_Empleado_DepartamentoId ON dbo.rh_Empleado (DepartamentoId);
END;
GO
