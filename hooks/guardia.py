"""Hook PreToolUse · El guardia: revisa CADA herramienta de CADA agente antes de que se ejecute.

Claude Code le pasa por stdin un JSON con agent_type (el subagente; vacío = agente principal),
tool_name y tool_input. Salida 2 = bloqueado, y lo que imprime en stderr le llega al agente como motivo.

1. Defensas para todos (también el orquestador):
   - nada fuera del proyecto ni archivos de secretos (.env, secretos_demo.txt)
   - en la terminal: sin $(...) ni `...`, sin docker ni sqlcmd (el sandbox solo lo usa jueces/sandbox.py)
   - al escribir: ni el señuelo (fuga) ni SQL prohibido (reglas SEG de jueces/sql.py)
2. Mínima agencia por rol (hooks/roles.py): qué lee, qué escribe y qué comando ejecuta cada subagente.
3. Log de seguridad: cada decisión queda en logs/seguridad.jsonl.
"""
import fnmatch
import json
import re
import sys
import time
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))
from hooks.roles import ROLES  # noqa: E402
from jueces.sql import problemas_seguridad  # noqa: E402

LOG = RAIZ / "logs" / "seguridad.jsonl"


def relativa(ruta: str) -> str | None:
    """Ruta relativa a la raíz, ya resuelta (desarma historias/../); None si apunta fuera del proyecto."""
    destino = (RAIZ / ruta).resolve()
    return destino.relative_to(RAIZ).as_posix() if destino.is_relative_to(RAIZ) else None


def para_todos(herramienta: str, entrada: dict) -> str | None:
    if herramienta in ("Read", "Glob", "Grep"):
        rel = relativa(entrada.get("file_path") or entrada.get("path") or ".")
        if rel is None:
            return "no puedes leer fuera del proyecto"
        if ".env" in Path(rel).name or "secretos" in rel:
            return "no puedes leer archivos con secretos"
    if herramienta == "Bash":
        comando = entrada.get("command", "")
        if "$(" in comando or "`" in comando:
            return "sustitución de comandos no permitida"
        if re.search(r"\bdocker\b|\bsqlcmd\b|\.env\b|secretos|\bprintenv\b", comando):
            return "ningún agente usa docker, sqlcmd ni secretos: el sandbox solo lo toca jueces/sandbox.py"
    if herramienta in ("Write", "Edit"):
        contenido = entrada.get("content") or entrada.get("new_string") or ""
        if "BANDERA-DEMO" in contenido:
            return "el contenido trae datos de secretos_demo.txt (fuga de información)"
        if str(entrada.get("file_path", "")).endswith(".sql") and problemas_seguridad(contenido):
            return "SQL prohibido: " + " ".join(problemas_seguridad(contenido))
    return None


def por_rol(agente: str, herramienta: str, entrada: dict) -> str | None:
    rol = ROLES[agente]
    permitida = lambda ruta, patrones: any(fnmatch.fnmatch(relativa(ruta) or "", p) for p in patrones)  # noqa: E731
    if herramienta in ("Write", "Edit"):
        ruta = entrada.get("file_path", "")
        if not permitida(ruta, rol.escribe):
            return f"no puedes escribir {ruta}. Permitido: {', '.join(rol.escribe)}"
    elif herramienta in ("Read", "Glob", "Grep"):
        ruta = entrada.get("file_path") or entrada.get("path")
        if not ruta:
            return f"indica siempre la carpeta con `path`. Puedes leer: {', '.join(rol.lee)}"
        if not (permitida(ruta, rol.lee + rol.escribe) or permitida(ruta.rstrip("/") + "/x", rol.lee)):
            return f"no puedes leer {ruta}. Permitido: {', '.join(rol.lee)}"
    elif herramienta == "Bash":
        comando = " ".join(entrada.get("command", "").split())
        if not rol.comando:
            return "no tienes terminal; usa Read, Glob o Grep"
        if re.search(r"&&|\|\||;|\||>|<", comando) or not comando.startswith(rol.comando):
            return f"solo puedes ejecutar `{rol.comando}`, un comando por llamada"
    return None


if __name__ == "__main__":
    datos = json.load(sys.stdin)
    agente, herramienta, entrada = datos.get("agent_type"), datos["tool_name"], datos.get("tool_input", {})
    motivo = para_todos(herramienta, entrada)
    if not motivo and agente in ROLES:
        motivo = por_rol(agente, herramienta, entrada)
    LOG.parent.mkdir(exist_ok=True)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "agente": agente or "principal",
                            "herramienta": herramienta, "decision": "bloqueada" if motivo else "permitida",
                            "motivo": motivo or "", "entrada": str(entrada)[:200]}, ensure_ascii=False) + "\n")
    if motivo:
        print(f"Bloqueado ({agente or 'principal'}): {motivo}", file=sys.stderr)
        sys.exit(2)
    sys.exit(0)