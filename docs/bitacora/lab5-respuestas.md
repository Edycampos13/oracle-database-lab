
## Parte G: diseño y coste de escritura

Evidencia: script/20261027T145614Z_06-indices.script.log.

Bloques modificados por fila, escenarios inicial/compañero/V005:
INSERT: 10,1/20,2/12,1.
UPDATE estado: 2/6/8,1.
UPDATE importe: 6/6/6.
DELETE: 10,1/20,2/10,1.

V005 acepta un mayor coste en ciertas escrituras para beneficiar
las consultas prioritarias. El cubriente reduce Q7 de 15 a 3 lecturas
(evidencia 03); el índice de código postal sirve Q3 con 106 lecturas
(evidencia 06). IX_PED_IMPORTE no se utilizó en la carga observada,
pero esa ventana breve no demuestra que nunca sea necesario.
IX_PED_CLIENTE se sustituye por un índice que empieza por ID_CLIENTE.
El índice parcial contiene solo pedidos pendientes.
El DNI único reduce la búsqueda de 1516 a 3 lecturas y garantiza unicidad
(evidencia 03).

## Parte K: multiplexación del redo

Se conservaron tres grupos de 200 MB y se añadió un segundo miembro
a cada uno. Tras dos cambios de log, redo02b.log seguía INVALID;
un tercer cambio activó el grupo 2 y todos los miembros quedaron
con estado vacío, sin INVALID.

Se omitieron las pruebas de borrado del script original:
con tres grupos, borrar uno no implica dejar menos de dos.
Las copias están en el mismo volumen y no protegen de perderlo.
Evidencias: script/*_10-redo.script.log y *_10-validar-miembros.script.log.

## Parte L: ARCHIVELOG y FRA llena

La base ya estaba en ARCHIVELOG. Se configuró la FRA en
/opt/oracle/oradata/fra con 4 GB mediante SCOPE=BOTH.
Configurar primero la ruta produjo ORA-19802; tamaño y luego ruta funcionó.

Al reducir temporalmente el límite a 2 MB en memoria, la secuencia 19
no pudo archivarse: ORA-16038 y ORA-19809.
Tras devolver el límite a 4 GB, las secuencias 19 y 20 quedaron
archivadas. La FRA terminó con 4096 MB de límite y 11 MB usados.
La secuencia 21 era CURRENT y aún no estaba archivada.

Evidencias: script/*_11-activar-archivelog.script.log y
script/*_11-fra-llena.script.log.

## Parte M: lectura consistente y coste del undo

B vio ACTIVO mientras A mantenía EGRESADO sin confirmar.
El intento de bloquear la fila produjo ORA-00054.
Tras el COMMIT, B vio EGRESADO; Flashback Query recuperó ACTIVO
desde undo y se reparó la fila 101 a ACTIVO.

Para 10 000 filas, undo/redo total/redo del rollback, en KB:
INSERT: 1128/4495/345.
UPDATE: 568/1258/751.
DELETE: 3416/6627/4701.

Los cambios del undo se protegen con redo. La recuperación puede
rehacer esos bloques antes de deshacer transacciones no confirmadas.
ROLLBACK aplica nuevos cambios y también genera redo.
UNDO_RETENTION=900 es un objetivo, no una garantía por sí solo.

Evidencias: script/*_12-lectura-consistente.script.log y
script/*_12-undo-y-redo.script.log.

## Simulacro A: caída de instancia

RTO observado: 5 segundos, desde antes de SHUTDOWN ABORT hasta
comprobar CDB/PDB abiertas y servicio healthy.
RPO observado: 0 para el cambio confirmado probado.
La fila 102 conservó EGRESADO; la 103 no conservó INACTIVO.
El alert log mostró crash recovery y aplicación de redo.
El script devolvió la fila 102 a ACTIVO.
Evidencia: script/*_14a-caida-instancia.script.log.

## Simulacro B: pérdida de un control file

RTO observado: 9 segundos, incluyendo la parada planificada,
el arranque fallido, diagnóstico, reparación y reapertura.
No se restauraron datos antiguos: se repuso control03.ctl desde
control01.ctl tras una parada limpia; no se observó pérdida de datos.
El arranque falló con ORA-00205 y quedó STARTED.
El alert log identificó control03.ctl con ORA-00202/ORA-27037.
Después quedaron activas las tres copias y CDB/PDB READ WRITE.
Evidencia: script/*_14b-perdida-controlfile.script.log.

## Simulacro C: borrado de tabla

DROP sin PURGE permitió recuperar ACA_MATRICULAS con Flashback Table:
60 000 filas. Tras DROP PURGE apareció ORA-00942.
La restauración completa de lab5-pre-simulacro devolvió las 60 000 filas.

Tiempo de restauración medido: 109 segundos.
Ventana potencial de pérdida indicada por el script: 2 segundos
entre la finalización de la copia y el fallo.
No equivale a dos segundos de datos de negocio perdidos:
la restauración vuelve al estado de la copia y descarta cambios posteriores.

Evidencia: script/*_14c-simulacro-restauracion.script.log.

## Simulacro D: pérdida del datafile

Se perdió el archivo 16, academia01.dbf.
La consulta falló con ORA-01116, ORA-01110 y ORA-27041.
FREEPDB1 quedó MOUNTED. RMAN ejecutó RESTORE y RECOVER,
se puso el archivo ONLINE y se abrió la PDB en READ WRITE.
La fila 104 conservó EGRESADO, confirmado después del backup:
no se perdió el cambio probado. Después se devolvió a ACTIVO.
RTO: 10 s de reparación y 11 s desde el fallo.
Se comprobaron 20 000 estudiantes.
Evidencia: script/*_14d-perdida-datafile.script.log.

## Retrospectiva de los simulacros

A: 5 s; B: 9 s; C: 109 s de restauración; D: 11 s desde el fallo.
Los intervalos medidos no son idénticos: cada apartado define su inicio.
C restauró todo el volumen y descartó cambios posteriores a la copia.
D recuperó un archivo aplicando redo y conservó el cambio posterior.
En D Oracle cerró toda FREEPDB1, así que el impacto superó TBS_ACADEMIA.

Mejora propuesta: probar periódicamente restauraciones, conservar
backups y redo en almacenamiento independiente y medir el RTO hasta
una consulta de negocio correcta. No basta con disponer de backups.

## Parte P: salud y verificación final

16-verificacion-final.sh terminó TODO OK.
La FRA usaba 93 de 4096 MB; había tres control files,
ningún grupo de redo con un solo miembro y backup RMAN COMPLETED.
Las filas 101, 102 y 104 estaban ACTIVO; había 60 000 matrículas.

Se investigó el aviso histórico de recuperación del archivo 26:
V$RECOVER_FILE no devolvió filas. Los archivos 16 (Academia) y
26 (TiendaSur) estaban ONLINE, sin error de cabecera y RECOVER=NO.
FREEPDB1 estaba READ WRITE. No quedó recuperación pendiente.
FUZZY=YES con la base abierta no acredita por sí solo un fallo.

Evidencias: script/*_15-healthcheck.script.log,
script/*_15-comprobar-recuperacion.script.log y
script/*_16-verificacion-final.script.log.
