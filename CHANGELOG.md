# Changelog

## [1.0.0] - 2026-11-08

### Agregado
- Cuatro subagentes: planificador, implementador, tester y revisor, y el orquestador `/fabrica`.
- Aprobación humana del plan (máximo 2 rechazos) y un ciclo de corrección tras la revisión.
- Jueces deterministas: entrada, convenciones y seguridad de SQL, plan y revisión.
- Sandbox de SQL Server 2022 en Docker; los scripts se ejecutan dos veces (idempotencia).
- Hooks: guardia (permisos por rol, defensas y log de seguridad) y compuerta (validación con tope).
- Historias HU-01, HU-02 y la historia de ataque HU-99.