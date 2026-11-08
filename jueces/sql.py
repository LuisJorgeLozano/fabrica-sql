"""Juez de SQL: revisa un script SIN ejecutarlo y devuelve la lista de problemas (vacía = válido).

- Reglas SEG (seguridad): para scripts y pruebas. Un script de la aplicación nunca toca el
  servidor, el sistema operativo ni los permisos.
- Reglas CNV (convenciones del equipo): solo para los scripts de bd/scripts/.

Las reglas se revisan sobre el código SIN comentarios ni contenido de cadenas (`limpiar()`):
así un comentario que dice «no uses xp_cmdshell» no cuenta como código que lo usa.
"""
import re
from pathlib import Path

CLAVE_APP = "rh"            # prefijo de tablas, vistas y procedimientos (2 a 5 letras minúsculas)
F = re.IGNORECASE | re.MULTILINE


def limpiar(texto: str) -> str:
    """Quita comentarios (/* */ y --) y vacía las cadenas ('...'), recorriendo carácter por carácter."""
    salida, i, n = [], 0, len(texto)
    while i < n:
        if texto.startswith("/*", i):                      # comentario de bloque
            fin = texto.find("*/", i + 2)
            i = n if fin == -1 else fin + 2
            salida.append(" ")
        elif texto.startswith("--", i):                    # comentario de línea
            fin = texto.find("\n", i)
            i = n if fin == -1 else fin
        elif texto[i] == "'":                              # cadena: se deja vacía ('')
            j = i + 1
            while j < n and not (texto[j] == "'" and texto[j + 1:j + 2] != "'"):
                j += 2 if texto[j:j + 2] == "''" else 1    # '' es una comilla escapada
            salida.append("''")
            i = j + 1
        else:
            salida.append(texto[i])
            i += 1
    return "".join(salida)


# --- Seguridad (scripts y pruebas) --------------------------------------------------
PROHIBIDO = {
    "SEG-1 acceso al sistema operativo o a otros servidores":
        r"\bxp_\w+|\bsp_configure\b|\bRECONFIGURE\b|\bOPENROWSET\b|\bOPENDATASOURCE\b|\bBULK\s+INSERT\b",
    "SEG-2 operaciones de base de datos o de servidor":
        r"\b(CREATE|ALTER|DROP)\s+DATABASE\b|^\s*USE\s+\w+|\bBACKUP\b|\bRESTORE\b|\bSHUTDOWN\b",
    "SEG-3 logins, usuarios o permisos":
        r"\b(CREATE|ALTER|DROP)\s+(LOGIN|USER|ROLE)\b|\bGRANT\b|\bDENY\b|\bREVOKE\b|\bEXEC(UTE)?\s+AS\b",
    "SEG-4 SQL dinámico":
        r"\bEXEC(UTE)?\s*\(|\bEXEC(UTE)?\s+@|\bsp_executesql\b",
    "SEG-5 borrado de objetos":
        r"\bTRUNCATE\s+TABLE\b|\bDROP\s+(TABLE|VIEW|PROC|PROCEDURE|FUNCTION)\b",
}


def problemas_seguridad(texto: str) -> list[str]:
    codigo = limpiar(texto)
    problemas = []
    for regla, patron in PROHIBIDO.items():
        hallazgo = re.search(patron, codigo, F)
        if hallazgo:
            problemas.append(f"{regla} está prohibido («{' '.join(hallazgo.group().split())}»).")
    return problemas


# --- Convenciones (solo scripts) -----------------------------------------------------
NOMBRES = [
    (r"CREATE\s+TABLE\s+([\w.]+)", rf"dbo\.{CLAVE_APP}_[A-Z]\w*", f"dbo.{CLAVE_APP}_NombreTabla"),
    (r"CREATE\s+OR\s+ALTER\s+VIEW\s+([\w.]+)", rf"dbo\.{CLAVE_APP}_VI_[A-Z]\w*", f"dbo.{CLAVE_APP}_VI_Nombre"),
    (r"CREATE\s+OR\s+ALTER\s+PROC(?:EDURE)?\s+([\w.]+)", rf"dbo\.{CLAVE_APP}_usp_[A-Z]\w*",
     f"dbo.{CLAVE_APP}_usp_Nombre"),
]
PREFIJO_RESTRICCION = {"PRIMARY": "PK_", "FOREIGN": "FK_", "REFERENCES": "FK_", "UNIQUE": "AK_",
                       "CHECK": "CK_", "DEFAULT": "DF_"}


def problemas_convenciones(texto: str) -> list[str]:
    codigo = limpiar(texto)
    problemas = []
    for patron, valido, ejemplo in NOMBRES:                                        # CNV-1
        for m in re.finditer(patron, codigo, F):
            if not re.fullmatch(valido, m.group(1)):
                problemas.append(f"CNV-1 el nombre «{m.group(1)}» debe ser como {ejemplo}.")
    for m in re.finditer(r"CONSTRAINT\s+(\w+)\s+(PRIMARY|FOREIGN|REFERENCES|UNIQUE|CHECK|DEFAULT)\b",
                         codigo, F):                                                # CNV-2
        prefijo = PREFIJO_RESTRICCION[m.group(2).upper()]
        if not m.group(1).startswith(prefijo):
            problemas.append(f"CNV-2 la restricción «{m.group(1)}» debe empezar con {prefijo}.")
    for m in re.finditer(r"CREATE\s+TABLE\s+([\w.]+)", codigo, F):                 # CNV-3
        if not re.search(r"OBJECT_ID\s*\(", codigo[max(0, m.start() - 300):m.start()], F):
            problemas.append(f"CNV-3 CREATE TABLE {m.group(1)} necesita antes IF OBJECT_ID(...) IS NULL.")
    for m in re.finditer(r"CREATE\s+(?!OR\s+ALTER)(VIEW|PROC|PROCEDURE)\b", codigo, F):
        problemas.append(f"CNV-3 usa CREATE OR ALTER {m.group(1).upper()} (idempotente).")
    if re.search(r"\bSELECT\s+(\w+\.)?\*", codigo, F):                             # CNV-4
        problemas.append("CNV-4 no uses SELECT *; lista las columnas.")
    if re.search(r"CREATE\s+OR\s+ALTER\s+PROC", codigo, F):                       # CNV-5
        for requisito in ("SET NOCOUNT ON", "BEGIN TRY", "BEGIN CATCH"):
            if not re.search(requisito.replace(" ", r"\s+"), codigo, F):
                problemas.append(f"CNV-5 el procedimiento debe incluir {requisito}.")
    return problemas


def problemas_sql(ruta: Path, texto: str | None = None) -> list[str]:
    """Todos los problemas de un .sql, cada uno con el nombre del archivo para que el agente sepa dónde corregir."""
    texto = ruta.read_text(encoding="utf-8") if texto is None else texto
    es_prueba = "pruebas" in ruta.parts
    problemas = problemas_seguridad(texto)
    if not es_prueba:
        problemas += problemas_convenciones(texto)
    formato, ejemplo = (r"CP-\d{2}_[a-z0-9_]+\.sql", "CP-01_alta_exitosa.sql") if es_prueba \
        else (r"\d{3}_[a-z0-9_]+\.sql", "001_tabla_departamento.sql")
    if not re.fullmatch(formato, ruta.name):                                      # CNV-6
        problemas.append(f"CNV-6 el archivo debe llamarse como {ejemplo}.")
    if not texto.lstrip().startswith("/*") or texto.rstrip().splitlines()[-1:] != ["GO"]:
        problemas.append("CNV-6 el archivo empieza con el encabezado /* ... */ y termina con GO.")
    return [f"{ruta.name} · {p}" for p in problemas]