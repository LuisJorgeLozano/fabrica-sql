# Reglas de negocio · Gestión de empleados (aplicación con clave `rh`)

## Departamento (catálogo)

| Campo | Regla |
| --- | --- |
| DepartamentoId | Entero, lo asigna el sistema |
| Nombre | Obligatorio, único, hasta 50 caracteres |

Valores iniciales: Tecnología, Ventas, Finanzas, Recursos Humanos, Operaciones.
El script los carga sin duplicarlos aunque se ejecute varias veces.

## Empleado

| Campo | Regla |
| --- | --- |
| EmpleadoId | Entero, lo asigna el sistema |
| NumeroEmpleado | Lo asigna el sistema con el formato EMP-0001, consecutivo; no se edita |
| Nombre | Obligatorio, de 2 a 80 caracteres |
| Correo | Obligatorio, hasta 120 caracteres, termina en @empresa.com, único sin importar mayúsculas; se guarda en minúsculas; no se edita |
| Puesto | Obligatorio, de 2 a 60 caracteres |
| DepartamentoId | Obligatorio; debe existir en el catálogo de departamentos |
| FechaIngreso | Obligatoria; no puede ser una fecha futura |
| Estado | «activo» al registrar; «baja» al dar de baja |
| FechaBaja | Solo cuando el estado es «baja»; no puede ser anterior a la fecha de ingreso |
| CreadoEn | Fecha y hora (UTC) de registro, la asigna el sistema |

## Errores de negocio

Los procedimientos almacenados reportan las reglas rotas con `THROW` y estos números exactos.
La aplicación muestra el mensaje tal cual, por eso el texto también es parte del contrato.

| Número | Mensaje | Cuándo |
| --- | --- | --- |
| 50001 | El correo ya está registrado | Alta con un correo que ya existe (sin importar mayúsculas) |
| 50002 | Usa el correo corporativo @empresa.com | El correo no termina en @empresa.com |
| 50003 | La fecha de ingreso no puede ser futura | FechaIngreso posterior a hoy |
| 50004 | No se puede editar a un empleado dado de baja | Cambio o baja de un empleado con estado «baja» |
| 50005 | El empleado no existe | Id de empleado inexistente |
| 50006 | El departamento no existe | Id de departamento inexistente |
| 50007 | Dato inválido: <campo> | Cualquier otro dato obligatorio vacío o fuera de longitud |
| 50008 | La fecha de baja no puede ser anterior a la fecha de ingreso | Baja con fecha anterior al ingreso |

## Reglas

1. La aplicación escribe SOLO mediante procedimientos almacenados; nunca directo en las tablas.
2. Dar de baja no borra al empleado: cambia su estado a «baja», guarda la fecha de baja y sigue en el directorio.
3. Toda modificación va en una transacción explícita y corta; si algo falla, se revierte y se relanza el error.
4. Las consultas del directorio no distinguen mayúsculas de minúsculas.
5. La seguridad de acceso (logins, usuarios, permisos) la administra el DBA: está fuera del alcance de la fábrica.