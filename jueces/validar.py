"""Valida lo que entrega un agente (lo usan la compuerta, el orquestador y tú).

Uso:  python -m jueces.validar salida/HU-01/plan.md
      python -m jueces.validar salida/HU-01/revision.json
      python -m jueces.validar bd/scripts/002_tabla_empleado.sql
Código de salida 0 = válido; 1 = hay problemas (se imprimen, escritos para que el agente corrija).
"""
import json
import re
import sys
from pathlib import Path

from jueces.sql import CLAVE_APP, problemas_sql

RAIZ = Path(__file__).resolve().parent.parent

SECCIONES_PLAN = ("## Criterios de aceptación", "## Tablas", "## Procedimientos", "## Tareas")


def escenarios(plan: str) -> list[str]:
    """Los escenarios de la especificación: cada uno necesitará al menos una prueba."""
    return re.findall(r"^\s*(?:[-#*]+\s*)?Escenario:\s*(.+?)\s*$", plan, flags=re.MULTILINE)


def validar_plan(texto: str) -> list[str]:
    """plan.md = especificación (criterios) + diseño + tareas, en menos de 70 líneas."""
    problemas = [f"Falta la sección «{s}»." for s in SECCIONES_PLAN if s not in texto]
    if len([l for l in texto.splitlines() if l.strip()]) > 70:
        problemas.append("El plan tiene más de 70 líneas; resúmelo para que una persona lo pueda revisar.")
    total = len(escenarios(texto))
    if total < 2:
        problemas.append("Se esperan al menos 2 escenarios («Escenario: ...»): el camino feliz y un error.")
    if len(re.findall(r"\bEntonces\b", texto)) < total:
        problemas.append("Cada escenario necesita su Dado / Cuando / Entonces.")
    tareas = texto.split("## Tareas", 1)[-1]
    if not re.search(r"\b\d{3}_[a-z0-9_]+\.sql\b", tareas):
        problemas.append("«## Tareas» debe listar los scripts a crear, por ejemplo 001_tabla_departamento.sql.")
    if f"{CLAVE_APP}_" not in texto:
        problemas.append(f"El plan no usa el prefijo de la aplicación «{CLAVE_APP}_».")
    return problemas


def validar_revision(texto: str) -> list[str]:
    """revision.json = {"aprobado": bool, "hallazgos": [{severidad, archivo, detalle}], "resumen": str}."""
    try:
        r = json.loads(texto)
    except json.JSONDecodeError as e:
        return [f"No es JSON válido: {e}"]
    if not isinstance(r.get("aprobado"), bool) or not isinstance(r.get("resumen"), str) \
            or not isinstance(r.get("hallazgos"), list):
        return ['Debe tener "aprobado" (true/false), "hallazgos" (lista) y "resumen" (texto).']
    problemas = []
    for i, h in enumerate(r["hallazgos"], 1):
        if h.get("severidad") not in ("alta", "media", "baja") or not h.get("archivo") or not h.get("detalle"):
            problemas.append(f'Hallazgo {i}: necesita "severidad" (alta/media/baja), "archivo" y "detalle".')
    if r["aprobado"] and any(h.get("severidad") == "alta" for h in r["hallazgos"]):
        problemas.append('Incoherente: hay hallazgos de severidad alta y "aprobado" es true.')
    return problemas


def problemas_de(ruta: Path) -> list[str] | None:
    """Problemas del archivo, o None si no sabemos validarlo."""
    if not ruta.exists():
        rel = ruta.resolve().relative_to(RAIZ) if ruta.resolve().is_relative_to(RAIZ) else ruta
        return [f"No existe {rel}."]
    if ruta.suffix == ".sql":
        return problemas_sql(ruta)
    if ruta.name == "plan.md":
        return validar_plan(ruta.read_text(encoding="utf-8"))
    if ruta.name == "revision.json":
        return validar_revision(ruta.read_text(encoding="utf-8"))
    return None


if __name__ == "__main__":
    problemas = problemas_de(Path(sys.argv[1]))
    if problemas is None:
        sys.exit(f"No sé validar {sys.argv[1]}")
    for p in problemas:
        print("-", p)
    print("válido" if not problemas else f"{len(problemas)} problema(s)")
    sys.exit(1 if problemas else 0)
