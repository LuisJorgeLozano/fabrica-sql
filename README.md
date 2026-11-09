# Fábrica de scripts SQL Server con subagentes de Claude Code

Cuatro agentes que convierten una **historia de usuario** en **scripts de SQL Server verificados**, con sus
**pruebas** y una **revisión**, siguiendo las convenciones del equipo. Corre con `claude auth login`
(plan Pro o Max), sin ANTHROPIC_API_KEY.

| # | Agente | Entrada | Salida |
| --- | --- | --- | --- |
| 1 | Planificador | Historia + reglas | `salida/HU-xx/plan.md`: especificación + tareas (lo aprueba una persona) |
| 2 | Implementador | Plan aprobado | `bd/scripts/NNN_*.sql` |
| 3 | Tester | Plan + scripts | `bd/pruebas/HU-xx/CP-*.sql` (ejecutadas en el sandbox) |
| 4 | Revisor | Plan + scripts | `salida/HU-xx/revision.json` |
| — | `/fabrica` (supervisor) | Historia | `salida/HU-xx/bitacora.md` |

```
/fabrica historias/HU-01-registrar-empleado.md
  1 entrada (código) → 2 planificador → 3 ¿apruebas? (persona) → 4 implementador → sandbox sql
  → 5 tester → sandbox pruebas → 6 revisor (1 ciclo de corrección) → 7 bitácora
```

## Seguridad

| Medida | Dónde |
| --- | --- |
| Entrada: la historia se revisa con código antes de que la lea un modelo | `jueces/entrada.py` |
| Prompt hardening: bloque `<reglas_de_seguridad>` en cada agente | `.claude/agents/*.md` |
| Validación de salidas: convenciones (CNV) y SQL prohibido (SEG) | `jueces/sql.py` |
| Sandbox: SQL Server en Docker, solo localhost, `bd/` de solo lectura, contraseña fuera del alcance de los agentes | `sandbox/levantar.sh`, `jueces/sandbox.py` |
| Permisos por rol y defensas para todos | `hooks/roles.py`, `hooks/guardia.py` |
| Log de seguridad | `logs/seguridad.jsonl` |

## Requisitos

macOS con Docker Desktop (en chip Apple, activa Rosetta), Python 3.12, `uv` y Claude Code con sesión iniciada.
No hay dependencias de Python: todo usa la biblioteca estándar.

## Instalación

```bash
uv venv --python 3.12
cp .env.example .env               # cambia la contraseña en las dos líneas
chmod +x sandbox/levantar.sh && ./sandbox/levantar.sh
.venv/bin/python -m jueces.sandbox estado
claude                             # la primera vez: acepta «¿confías en esta carpeta?» y sal con /exit
```

## Uso

```
claude
> /fabrica historias/HU-01-registrar-empleado.md
```

Sin interacción: `claude -p "/fabrica historias/HU-02-consultar-directorio.md --aprobar" --permission-mode acceptEdits`.
Cada agente se puede usar solo: `/plan`, `/implementar`, `/probar`, `/revisar`.

## Pruebas

```bash
.venv/bin/python -m jueces.sandbox sql             # convenciones + ejecución de todos los scripts, dos veces
.venv/bin/python -m jueces.sandbox pruebas HU-01   # pruebas T-SQL de una historia
.venv/bin/python -m jueces.validar bd/scripts/002_tabla_empleado.sql
.venv/bin/python -m jueces.entrada historias/HU-99-envenenada.md   # debe salir BLOQUEADA
```

## Otra aplicación

Cambia `CLAVE_APP` en `jueces/sql.py` y la clave en `contexto/convenciones_sql.md`, reemplaza
`contexto/reglas_negocio.md` y escribe sus historias.