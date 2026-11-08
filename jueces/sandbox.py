"""Ejecuta los scripts y las pruebas en el sandbox de SQL Server (Docker). El código decide, no el agente.

Uso:  python -m jueces.sandbox estado
      python -m jueces.sandbox sql              (base nueva, todos los scripts, DOS vueltas)
      python -m jueces.sandbox pruebas HU-01    (base nueva + scripts + pruebas de la historia)
Código de salida 0 = pasó; 1 = falló (el log dice por qué).

Seguridad del sandbox: el contenedor solo escucha en localhost, ve bd/ en SOLO LECTURA y guarda la
contraseña en su propia variable SQLCMDPASSWORD: ni este código ni ningún agente la ve nunca.
"""
import subprocess
import sys
from pathlib import Path

from jueces.sql import problemas_sql
from jueces.validar import escenarios

RAIZ = Path(__file__).resolve().parent.parent
BD = RAIZ / "bd"


def sqlcmd(*argumentos: str) -> tuple[bool, str]:
    """sqlcmd dentro del contenedor. -b: cualquier error de SQL = salida ≠ 0 · -C: certificado local · -f 65001: UTF-8."""
    comando = ["docker", "exec", "fabrica-sql", "/opt/mssql-tools18/bin/sqlcmd", "-S", "localhost", "-U", "sa",
               "-C", "-b", "-I", "-f", "65001", *argumentos]
    try:
        r = subprocess.run(comando, capture_output=True, text=True, timeout=180)
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        return False, f"No pude usar docker: {e}"
    return r.returncode == 0, (r.stdout + r.stderr).strip()[-3000:]


def preparar(base: str) -> tuple[bool, str]:
    """¿Responde el sandbox? Si sí, borra y crea la base de pruebas (esto solo lo hace el código, nunca un script)."""
    ok, log = sqlcmd("-Q", "SELECT 1;")
    if not ok:
        return False, f"El sandbox no responde. Una PERSONA debe levantarlo: ./sandbox/levantar.sh\n{log}"
    return sqlcmd("-Q", f"IF DB_ID(N'{base}') IS NOT NULL BEGIN ALTER DATABASE {base} SET SINGLE_USER "
                        f"WITH ROLLBACK IMMEDIATE; DROP DATABASE {base}; END; CREATE DATABASE {base};")


def ejecutar(archivo: Path, base: str) -> tuple[bool, str]:
    """El contenedor ve bd/ en /bd: ejecuta el archivo desde ahí."""
    return sqlcmd("-d", base, "-i", "/bd/" + archivo.relative_to(BD).as_posix())


def verificar_sql(hu: str | None = None) -> tuple[bool, str]:
    scripts = sorted((BD / "scripts").glob("*.sql"))
    if not scripts:
        return False, "No hay scripts en bd/scripts/."
    problemas = [p for s in scripts for p in problemas_sql(s)]       # 1. estático: lo prohibido nunca llega a SQL Server
    if problemas:
        return False, "Revisión estática:\n" + "\n".join(f"- {p}" for p in problemas)
    ok, log = preparar("SANDBOX_SQL")
    if not ok:
        return False, log
    lineas = []
    for vuelta in (1, 2):                                            # 2. dinámico, dos veces = idempotencia
        for s in scripts:
            ok, log = ejecutar(s, "SANDBOX_SQL")
            lineas.append(f"[vuelta {vuelta}] {'OK   ' if ok else 'FALLA'} {s.name}")
            if not ok:
                causa = "NO es idempotente (falló la segunda vez)" if vuelta == 2 else "SQL Server lo rechazó"
                return False, "\n".join(lineas) + f"\n\n{s.name}: {causa}:\n{log}"
    return True, "\n".join(lineas)


def verificar_pruebas(hu: str | None) -> tuple[bool, str]:
    if not hu:
        return False, "Uso: python -m jueces.sandbox pruebas HU-xx"
    pruebas = sorted((BD / "pruebas" / hu).glob("*.sql"))
    plan = RAIZ / "salida" / hu / "plan.md"
    esperados = len(escenarios(plan.read_text(encoding="utf-8"))) if plan.exists() else 1
    if len(pruebas) < esperados:                                     # trazabilidad: una prueba por escenario
        return False, f"Hay {len(pruebas)} pruebas en bd/pruebas/{hu}/ y el plan tiene {esperados} escenarios."
    problemas = [p for a in pruebas for p in problemas_sql(a)]
    if problemas:
        return False, "Revisión estática de las pruebas:\n" + "\n".join(f"- {p}" for p in problemas)
    ok, log = preparar("SANDBOX_PRUEBAS")
    if not ok:
        return False, log
    for s in sorted((BD / "scripts").glob("*.sql")):
        ok, log = ejecutar(s, "SANDBOX_PRUEBAS")
        if not ok:
            return False, f"Los scripts no se instalan ({s.name}); primero debe pasar `jueces.sandbox sql`:\n{log}"
    lineas, fallas = [], []
    for p in pruebas:
        ok, log = ejecutar(p, "SANDBOX_PRUEBAS")
        lineas.append(f"{'OK   ' if ok else 'FALLA'} {p.name}")
        if not ok:
            fallas.append(f"--- {p.name}\n{log}")
    lineas.append(f"{len(pruebas) - len(fallas)} de {len(pruebas)} pruebas pasaron.")
    return not fallas, "\n".join(lineas + fallas)


VERIFICACIONES = {"estado": lambda hu: preparar("SANDBOX_SQL"), "sql": verificar_sql, "pruebas": verificar_pruebas}

if __name__ == "__main__":
    nombre = sys.argv[1] if len(sys.argv) > 1 else ""
    if nombre not in VERIFICACIONES:
        sys.exit(f"Uso: python -m jueces.sandbox {{{'|'.join(VERIFICACIONES)}}} [HU-xx]")
    ok, log = VERIFICACIONES[nombre](sys.argv[2] if len(sys.argv) > 2 else None)
    print(log)
    print("\nVERIFICACIÓN:", "OK" if ok else "FALLA")
    sys.exit(0 if ok else 1)