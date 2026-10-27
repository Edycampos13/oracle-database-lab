# Lab 4 — Informe de autopsia

## Alcance y estado observado

Ejecución de 26 de octubre de 2026. Fuente principal: `evidencia/script/20261026T172944Z_15-autopsia-instancia.script.log`; se complementa con las evidencias 06, 10, 11 y 16. Los timestamps SQL/log son los emitidos por la base; el alert log detallado incluye UTC.

Instancia FREE, Oracle 23.26.3.0.0, host 979ebb9617bc, OPEN/ACTIVE. Base FREE, DBID 1509902213, PRIMARY, ARCHIVELOG, FORCE_LOGGING=YES y FLASHBACK_ON=NO. CDB$ROOT y FREEPDB1 abiertas en lectura/escritura; PDB$SEED en solo lectura.

## Hallazgos y acciones

| Hallazgo y evidencia | Riesgo | Acción propuesta | Prioridad |
|---|---|---|---|
| ARCHIVELOG activo, FRA vacía y tamaño 0; E15 sección 4. E06 muestra destino de archivado por defecto bajo dbs/arch. | El archivado necesita control explícito de ubicación, capacidad y retención; ARCHIVELOG por sí solo no garantiza recuperación. | Configurar FRA, vigilar espacio y establecer respaldos/retención con RMAN durante Lab 5. | Alta |
| Dos control files en /opt/oracle/oradata/FREE; E11. | Las dos copias comparten volumen y dominio de fallo. | Multiplexar según el ejercicio y distinguir copia de archivo de independencia real del almacenamiento. | Alta |
| Tres grupos de redo, un miembro de 200 MB por grupo; E11/E15. | La pérdida de un miembro puede comprometer disponibilidad o recuperación según estado del grupo. | Añadir miembros y planificar dominios independientes; comprobar estados. | Alta |
| ADR fuera del volumen; E11 Linux. | Recrear el contenedor borra alert log y trazas. | Persistir el diagnóstico o enviarlo a almacenamiento externo antes de recrear. | Media |
| ALTURA_MAX vacía para Clínica, Fintech, Logística y Retail; E15 sección 6. | Las estadísticas disponibles no permiten evaluar bien esos índices; la ausencia de altura no prueba por sí sola que todo el esquema carezca de estadísticas. | Revisar tablas/índices, datos y estadísticas; recogerlas cuando proceda y volver a medir. | Media |
| Dos índices de Academia con clustering factor superior a la mitad de las filas; E15 sección 6. | Algunos accesos por rangos pueden requerir muchas visitas a tabla. | Analizar consultas y selectividad antes de modificar índices en Lab 5. | Baja |
| Cuatro registros ORA-00800; E15. E06 detalla Set Priority Failed en VKTM/LGWR y Operation not permitted. | La prioridad solicitada no se aplica; el efecto de rendimiento no está cuantificado. | Conservar trazas y revisar requisitos del entorno. No ampliar privilegios del contenedor sin diagnóstico y justificación. | Media |
| Aviso de escrituras de redo lentas en E06 a las 17:07:37 UTC. | Posible latencia de confirmaciones o inestabilidad de rendimiento. | Correlacionar esperas de redo y carga de host/almacenamiento si se repite. | Media |
| ORA-65025 durante el intento de borrar PDB_LAB4 abierta; E10/E15. | Error provocado por la prueba; no demuestra un fallo persistente. | Documentar. El cierre y DROP posteriores funcionaron. | Informativa |
| Un registro ORA-959 en E15 a las 17:25. | El recuento no identifica por sí solo la sentencia responsable. | Recuperar contexto exacto antes de atribuir causa; la limpieza de TBS_LAB4 y la verificación final sí fueron correctas. | Pendiente de diagnóstico |

## Evidencia de estado correcto

- 16 datafiles, 3964 MB; tres tempfiles, 60 MB; dos control files, 36 MB; tres miembros de redo, 600 MB; tres registros de archived log no marcados borrados, 131 MB según V$ARCHIVED_LOG. El catálogo no sustituye comprobar la existencia de cada archivo.
- Cinco tablespaces de negocio ONLINE, datafiles en FREE/FREEPDB1 y techo de 1 GB.
- Academia: 20 000 estudiantes, 40 asignaturas y 60 000 matrículas. Fila 101 ACTIVO.
- C##OPS_RO sin DBA ni privilegios ANY de escritura y con SELECT específico sobre V_$DIAG_ALERT_EXT. El informe no mostró cuentas propias con rol DBA.
- PDB_LAB4, usuarios temporales y TBS_LAB4 eliminados; índice de prueba reparado antes de limpiar.
- Respaldo lab3-final íntegro según SHA-256. No se ha medido restauración ni acreditado una prueba de restauración.
- E16: `RESULTADO: TODO OK. Lab 4 listo para entregar.` Es una comprobación técnica, no la acreditación de todos los requisitos documentales o de GitHub.

## Interpretación del rendimiento

Los experimentos mostraron cero lecturas físicas en caché caliente, reutilización de cursor con bind y uso de TEMP con PGA limitada. Los tiempos pertenecen a Docker/WSL2 y pueden incluir caché de Linux y carga del host; no representan latencia directa de un disco de producción.

## Estado de cierre actualizado

Las comprobaciones posteriores resolvieron las rutas del SPFILE y
password file y el contexto de ORA-959, como se detalla a continuación.
Los retos realizados están documentados en lab4-respuestas.md.
La última verificación técnica termina TODO OK.
Siguen pendientes la revisión del PR, el cierre en GitHub y el respaldo
lab4-final. El RTO de restauración no se ha medido.
Los hallazgos originales de la tabla representan el diagnóstico inicial;
las comprobaciones posteriores actualizan su estado.

## Comprobaciones posteriores

El SPFILE y el password file resuelven respectivamente a
/opt/oracle/oradata/dbconfig/FREE/dbs/spfileFREE.ora y
/opt/oracle/oradata/dbconfig/FREE/dbs/orapwFREE.
La carpeta $ORACLE_HOME/dbs completa es un enlace al volumen.
Por tanto, ambos archivos persisten al recrear el contenedor.
Evidencia: script/*_11-rutas-configuracion.script.log.

El registro ORA-959 de las 17:25:52 UTC corresponde a
DROP TABLESPACE IF EXISTS tbs_lab4 INCLUDING CONTENTS AND DATAFILES,
en la preparación del banco de capacidad. Inmediatamente después
el alert log confirma la creación correcta de TBS_LAB4.
La limpieza posterior y la verificación final terminaron correctamente.
Se cierra este punto de diagnóstico.
Evidencia: script/*_15-contexto-ora00959.script.log.
