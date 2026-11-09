# Plan HU-02 · Consultar el directorio de empleados

Extiende HU-01 (scripts 001 a 004). Solo lectura: no hay tablas nuevas ni transacciones.

## Criterios de aceptación

- Escenario: Listar el directorio completo
  - Dado que existen Ana Pérez (EMP-0001, Tecnología, activo) y Luis Gómez (EMP-0002, Ventas, baja)
  - Cuando se ejecuta dbo.rh_usp_EmpleadoConsultar sin parámetros
  - Entonces devuelve ambos con NumeroEmpleado, Nombre, Correo, Puesto, Departamento y Estado, ordenados por Nombre
- Escenario: Buscar por nombre sin importar mayúsculas
  - Dado el empleado "Ana Pérez"
  - Cuando se consulta con @Busqueda = N'ANA pé'
  - Entonces devuelve a Ana Pérez
- Escenario: Buscar por correo sin importar mayúsculas
  - Dado el correo ana.perez@empresa.com
  - Cuando se consulta con @Busqueda = N'ANA.PEREZ@EMPRESA'
  - Entonces devuelve a Ana Pérez
- Escenario: Filtrar por departamento
  - Dado empleados en Tecnología y en Ventas
  - Cuando se consulta con @DepartamentoId de Ventas
  - Entonces solo devuelve empleados de Ventas
- Escenario: Búsqueda y departamento combinados
  - Dado "Ana Pérez" en Tecnología y "Ana Ruiz" en Ventas
  - Cuando se consulta con @Busqueda = N'ana' y @DepartamentoId de Ventas
  - Entonces devuelve solo a Ana Ruiz
- Escenario: Sin resultados
  - Dado que ningún empleado contiene "zzzz"
  - Cuando se consulta con @Busqueda = N'zzzz'
  - Entonces devuelve un conjunto vacío con las mismas columnas y sin error
- Escenario: Los empleados dados de baja siguen en el directorio
  - Dado Luis Gómez con Estado = «baja»
  - Cuando se consulta con @Busqueda = N'luis'
  - Entonces aparece con Estado = «baja»
- Escenario: Error, departamento inexistente
  - Dado que no existe el DepartamentoId 99999
  - Cuando se consulta con @DepartamentoId = 99999
  - Entonces falla con 50006 «El departamento no existe»
- Escenario: Error, búsqueda fuera de longitud
  - Dado un texto de búsqueda de 121 caracteres
  - Cuando se consulta con ese @Busqueda
  - Entonces falla con 50007 «Dato inválido: Busqueda»

## Tablas

No se crean ni modifican tablas. Se lee de dbo.rh_Empleado y dbo.rh_Departamento (HU-01).

Vista dbo.rh_VI_Directorio (sin tabla nueva), columnas:
- EmpleadoId int, NumeroEmpleado nvarchar, Nombre nvarchar(80), Correo nvarchar(120), Puesto nvarchar(60)
- DepartamentoId int, Departamento nvarchar(50) (Nombre del departamento), Estado nvarchar(10)
- Une con INNER JOIN explícito rh_Empleado y rh_Departamento; lista de columnas, sin SELECT *.

## Procedimientos

- dbo.rh_usp_EmpleadoConsultar
  - Parámetros: @Busqueda nvarchar(120) = NULL, @DepartamentoId int = NULL
  - Valida: @Busqueda con más de 120 caracteres produce 50007 «Dato inválido: Busqueda»; @DepartamentoId no nulo que no existe en dbo.rh_Departamento produce 50006 «El departamento no existe».
  - Un @Busqueda NULL o vacío (tras recortar espacios) no filtra por texto; @DepartamentoId NULL no filtra por departamento.
  - Devuelve: conjunto con EmpleadoId, NumeroEmpleado, Nombre, Correo, Puesto, DepartamentoId, Departamento y Estado, desde dbo.rh_VI_Directorio, ordenado por Nombre y EmpleadoId. Coincidencia por contenido en Nombre o Correo, comparando en minúsculas ambos lados (LOWER) para no depender del collation.
  - Solo lectura: sin transacción ni escritura; NOCOUNT y XACT_ABORT activos.

## Tareas

- 005_vista_directorio.sql: crea con CREATE OR ALTER la vista dbo.rh_VI_Directorio (empleado + departamento).
- 006_usp_empleado_consultar.sql: crea con CREATE OR ALTER dbo.rh_usp_EmpleadoConsultar con validaciones 50006 y 50007, búsqueda y filtro.

## Preguntas abiertas

- ¿La búsqueda debe tratar % y _ como texto literal? Se propone escaparlos para que sean literales.
- ¿El directorio debe poder ocultar a los dados de baja? La historia no lo pide; se incluyen todos.
- ¿Se requiere paginación? No se menciona; se omite.
