
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
