"""Hook SubagentStop · Un subagente no termina hasta que el CÓDIGO dice que su trabajo es válido.

Si su entrega no pasa jueces/validar.py, o su verificación no pasa jueces/sandbox.py, respondemos
{"decision": "block", "reason": ...}: el subagente recibe los problemas como instrucción y vuelve a
intentarlo. Después de max_intentos lo dejamos terminar y avisamos a la persona (todo bucle tiene límite).
"""
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))
from hooks.roles import ROLES  # noqa: E402
from jueces.sandbox import VERIFICACIONES  # noqa: E402
from jueces.validar import problemas_de  # noqa: E402

CONTADORES = RAIZ / "salida" / ".compuerta"


def tarea(transcripcion: str | None) -> str:
    """La primera línea «user» de la transcripción del subagente es la tarea que recibió (trae el HU-xx)."""
    try:
        for linea in open(transcripcion, encoding="utf-8"):
            d = json.loads(linea)
            if d.get("type") == "user":
                return json.dumps(d["message"]["content"], ensure_ascii=False)
    except (OSError, TypeError, ValueError, KeyError):
        pass
    return ""


if __name__ == "__main__":
    datos = json.load(sys.stdin)
    agente = datos.get("agent_type")
    rol = ROLES.get(agente)
    hu = re.search(r"HU-\d+", tarea(datos.get("agent_transcript_path")))
    if not rol or not hu:                          # sin rol o sin HU-xx en la tarea: no hay nada que revisar
        sys.exit(0)
    hu = hu.group()

    problemas = []
    if rol.entrega:
        problemas = problemas_de(RAIZ / "salida" / hu / rol.entrega) or []
    if rol.verifica and not problemas:
        ok, log = VERIFICACIONES[rol.verifica](hu)
        if not ok:
            problemas = [f"La verificación «{rol.verifica}» falló:\n{log}"]
    if not problemas:
        sys.exit(0)                                # válido: puede terminar

    CONTADORES.mkdir(parents=True, exist_ok=True)
    contador = CONTADORES / f"{datos.get('agent_id', agente)}.txt"
    intentos = int(contador.read_text()) if contador.exists() else 0
    if intentos >= rol.max_intentos:               # tope: decide una persona
        print(json.dumps({"systemMessage": f"{agente} ({hu}) sigue sin pasar tras {intentos} correcciones; "
                                           "revisa a mano:\n- " + "\n- ".join(problemas)}, ensure_ascii=False))
        sys.exit(0)
    contador.write_text(str(intentos + 1))
    print(json.dumps({"decision": "block", "reason": f"Corrección {intentos + 1} de {rol.max_intentos} en {hu}. "
                      "Corrige esto y vuelve a guardar:\n- " + "\n- ".join(problemas)}, ensure_ascii=False))