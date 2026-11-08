"""Seguridad en la ENTRADA: revisa una historia ANTES de que la lea cualquier modelo.

Uso: python -m jueces.entrada historias/HU-01-registrar-empleado.md
Código de salida 0 = pasa; 1 = bloqueada (imprime el motivo).
Es código: no gasta cuota y no se puede «convencer». Si da un falso positivo, decide una persona.
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SOSPECHOSO = {
    "da instrucciones a un asistente de IA": r"asistente de ia|ignora (las|tus|todas)|nuevas instrucciones",
    "menciona rutas fuera del proyecto o secretos": r"\.\./|/etc/|\.env\b|secretos?_|variables de entorno",
    "pide operaciones de servidor o de permisos": r"xp_cmdshell|sp_configure|sysadmin|create login|drop database",
    "pide ocultar información": r"no (lo )?menciones|no (lo )?digas",
}


def revisar(ruta: Path) -> list[str]:
    destino = (RAIZ / ruta).resolve()
    if not destino.is_relative_to(RAIZ / "historias") or not destino.exists():
        return [f"La historia debe existir dentro de historias/: {ruta}"]
    texto = destino.read_text(encoding="utf-8")
    problemas = [f"La historia es demasiado larga ({len(texto)} caracteres)."] if len(texto) > 4000 else []
    for motivo, patron in SOSPECHOSO.items():
        hallazgo = re.search(patron, texto, re.IGNORECASE)
        if hallazgo:
            problemas.append(f"La historia {motivo}: «{hallazgo.group()}».")
    return problemas


if __name__ == "__main__":
    problemas = revisar(Path(sys.argv[1]))
    for p in problemas:
        print("-", p)
    print("ENTRADA: BLOQUEADA" if problemas else "ENTRADA: OK")
    sys.exit(1 if problemas else 0)