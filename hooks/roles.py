"""La tabla de permisos de cada subagente: mínima agencia escrita como código.

Los aplica hooks/guardia.py ANTES de cada herramienta, y hooks/compuerta.py cuando el agente quiere terminar.

- lee / escribe: patrones de rutas (fnmatch: * también cruza /, así bd/* incluye bd/scripts/x.sql)
- comando:       el ÚNICO comando de terminal que puede ejecutar (None = sin terminal)
- entrega:       archivo de salida/HU-xx/ que debe quedar válido para poder terminar
- verifica:      verificación del sandbox que debe pasar para poder terminar
- max_intentos:  cuántas veces la compuerta lo devuelve antes de escalar a una persona
"""
from dataclasses import dataclass


@dataclass
class Rol:
    lee: list[str]
    escribe: list[str]
    comando: str | None = None
    entrega: str | None = None
    verifica: str | None = None
    max_intentos: int = 2


ROLES = {
    # Agente 1 · especificación + plan dividido en tareas; no escribe SQL
    "planificador": Rol(lee=["historias/*", "contexto/*", "salida/*", "bd/*"],
                        escribe=["salida/*/plan.md"],
                        entrega="plan.md"),
    # Agente 2 · escribe los scripts; no termina hasta que pasan el juez y el sandbox
    "implementador": Rol(lee=["contexto/*", "salida/*", "bd/*"],
                         escribe=["bd/scripts/*"],
                         comando=".venv/bin/python -m jueces.sandbox sql",
                         verifica="sql"),
    # Agente 3 · escribe y ejecuta las pruebas; NO puede tocar los scripts que prueba
    "tester": Rol(lee=["contexto/*", "salida/*", "bd/*"],
                  escribe=["bd/pruebas/*"],
                  comando=".venv/bin/python -m jueces.sandbox pruebas",
                  verifica="pruebas"),
    # Agente 4 · revisa la calidad; solo opina en su revision.json
    "revisor": Rol(lee=["contexto/*", "salida/*", "bd/*"],
                   escribe=["salida/*/revision.json"],
                   entrega="revision.json"),
}