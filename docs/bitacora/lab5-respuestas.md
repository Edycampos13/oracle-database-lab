# Lab 5 — Oracle DBA Workflow II

Ejecución: 26–27 de octubre de 2026. Oracle Free 23.26.3.0.0 en Docker/WSL2. Las cifras son las de las evidencias del alumno. Las referencias indican el número y sufijo del archivo en `docs/bitacora/lab5/evidencia/`; las respuestas no sustituyen los logs.

## Preguntas de comprobación

1. **Cobertura de las copias.** La copia lab4-final terminó íntegra, con toda la base dentro del volumen. En este equipo, el diagnóstico inicial del Lab 4 mostró que `$ORACLE_HOME/dbs` ya enlazaba al volumen: no se puede afirmar que la copia lab3-final tuviera cinco archivos fuera solo porque así suceda en el ejemplo del profesor. Se reubicaron las cinco rutas a FREE/FREEPDB1 y se verificó su persistencia. Evidencias: Lab 4, 01-diagnostico-inicial, 00-backup-lab3 y 03-prueba-persistencia; Lab 5, 00-backup-lab4.

2. **Factor de bloqueo.** CLIENTE: 100000/1517≈65,92, unas 66 filas/bloque. PEDIDO: 1000000/5320≈187,97, unas 188. PEDIDO tiene filas medias de 32 bytes frente a 102 en CLIENTE, por lo que caben más por bloque. Son promedios obtenidos de estadísticas, no una capacidad uniforme de cada bloque. Evidencia 01-perfil-confirmacion.

3. **Medir la segunda ejecución.** La primera calienta cachés y puede incluir análisis, limpieza de bloques y trabajo inicial. Medir la segunda reduce esos efectos al comparar en caliente. No representa por sí sola el rendimiento con caché fría ni una distribución completa de latencias. Evidencias 01-herramienta-medir y 02-anatomia.

4. **IX_PED_CLIENTE.** Altura 3, 2216 hojas y 6 ramas. Fan-out medio real: (2216+6−1)/6≈370. La estimación de capacidad máxima de rama fue 543. El modelo del script proyectó altura 4 con mil millones de filas, unas 5 lecturas para índice más tabla. Es una proyección, no una carga ejecutada con ese volumen. Evidencia 02.

5. **ROWID de una hoja.** La primera entrada de PK_CLIENTE tenía clave `c1 02` (cliente 1) y seis bytes `00 00 03 1b 00 00`: bloque 0x31b=795 y slot 0. En este índice sobre tablespace BIGFILE, el localizador usa cuatro bytes de bloque y dos de slot; el único datafile del tablespace se conoce por el contexto del segmento. Evidencia 02, comparación con DBMS_ROWID.

6. **Tres tipos de índice.** DNI: 1516 lecturas sin índice y 3 con UNIQUE, que además rechazó el duplicado. Historial Q7: 15 con índice simple, 7 con compuesto y 3 con cubriente, eliminando ordenación y finalmente acceso a tabla. Validación por token: heap+PK 4, IOT 3 y hash 1; el hash no beneficia del mismo modo a rangos y su limpieza costó 2770 lecturas. Evidencia 03-tipos-indice.

7. **Clustering factor.** FECHA_PEDIDO está correlacionada con el orden físico: CF=5220, próximo a 5320 bloques. ID_CLIENTE se reparte por la tabla: CF=999041, próximo al millón de filas. CF cuenta cambios de bloque recorriendo el índice, incluidas revisitas; no solo bloques distintos. REBUILD del índice no reordena las filas de la tabla y no resuelve esa causa. Evidencia 04.

8. **Punto de equilibrio.** Con CF malo, al 0,5 % el índice hizo 4875 lecturas y el full scan 5232; al 1 % hizo 9920. El cruce medido queda entre ambos porcentajes, cerca del modelo 1/188≈0,53 %. Con CF bueno, al 50 % hizo 3938 y al 100 % 7875: el cruce queda entre 50 y 100 %, sin precisar más con estos puntos. El optimizador eligió full scan desde 0,2 % para CF malo porque su modelo incluye costes adicionales, no solo buffers. Evidencia 04.

9. **Gonz%.** El prefijo permite un rango B-tree, pero los 2056 resultados provocaron acceso disperso a tabla: 2024 lecturas, superior a las aproximadamente 1500 de un full scan de CLIENTE. Usar un índice no garantiza menor coste. LIKE '%ez' devuelve otro conjunto: no es una reescritura equivalente. Evidencia 05.

10. **Escritura y propuesta.** INSERT con 4/9/5 índices modificó 10,1/20,2/12,1 bloques por fila. CANAL y FEC_CLI no se usaron en la carga observada; FEC_CLI añadía un orden de columnas que no ganó en esas consultas. Se evitó el índice general de ESTADO en favor del parcial; el promedio 1/NDV no describe el sesgo de sus estados. CP sí se conservó (Q3: 106 lecturas) y CLI_FEC se sustituyó por el cubriente (Q7: 3 lecturas en evidencia 03). IMPORTE no tuvo uso en la ventana; esa ventana corta no demuestra ausencia de uso en producción. Evidencia 06.

11. **Divisiones y cola.** AZAR: 595 splits, ninguno 90/10, 596 hojas y 75,4 % de ocupación. CRECIENTE: 398 splits 90/10, 399 hojas y 99,9 %. La cola dejó 224 hojas vacías a la izquierda y hojas llenas a la derecha, con 226 lecturas para el siguiente mensaje. El 69 % del modelo aleatorio no obliga a que una muestra finita coincida exactamente. Evidencias 07a/07b y gráficos.

12. **Remedio elegido.** En este caso COALESCE redujo el siguiente mensaje de 226 a 2 lecturas y dejó 201 hojas sin disminuir los 4 MB del segmento. Lo elegiría para ese síntoma tras evaluar concurrencia y recursos. SHRINK redujo además el segmento a 1,69 MB. REBUILD dejó 223 hojas y 2 MB sin mejorar las 2 lecturas. Las operaciones online pueden requerir bloqueos breves; no significan ausencia absoluta de impacto. Un cambio de diseño, como particiones con retención, debe evaluarse según edición y carga. Evidencia 07c.

13. **SCN de checkpoint.** Oracle contrasta metadatos del control file y cabeceras, incluido el checkpoint SCN, junto con la información necesaria de consistencia/recuperación. Antes: 6225645 en ambas ubicaciones; tras checkpoint: 6233750. CURRENT_SCN era mayor y seguía avanzando. PDB$SEED mantuvo 2098101 por estar en solo lectura. Igualdad de dos SCN no sustituye todas las comprobaciones de recuperación. Evidencia 08.

14. **Control files multiplexados.** Tres archivos en el mismo volumen permiten reparar la pérdida individual de una copia, demostrado en B. No protegen de la pérdida del volumen. En producción se buscan dominios de fallo independientes y backups de control file. Evidencias 09 y 14b.

15. **Redo y pruebas omitidas.** CURRENT es el grupo donde escribe LGWR; ACTIVE aún se necesita para recuperación de instancia; INACTIVE ya no se necesita para esa recuperación. El archivado es otra condición. La premisa del enunciado de que los tres intentos de borrado necesariamente fallan no es válida con tres grupos: eliminar uno elegible podría dejar dos y funcionar. Por eso se omitió el bloque de borrados. Tras un tercer switch quedaron tres grupos con dos miembros y ninguno INVALID. Evidencias 10-redo y 10-validar-miembros.

16. **FRA llena.** Al limitarla a 2 MB apareció ORA-19815 de capacidad y ORA-19809 por límite excedido; ORA-16038 informó que la secuencia 19 no se podía archivar. Si LGWR necesita reutilizar un grupo que no se ha podido archivar, las sesiones pueden esperar y el servicio de escritura detenerse. El ejercicio recuperó espacio antes de demostrar un bloqueo general: se volvió a 4 GB y se archivaron 19 y 20. Evidencia 11-fra-llena.

17. **Lectura consistente.** B leyó ACTIVO aunque A tenía EGRESADO sin confirmar: la consulta ordinaria no esperó al bloqueo de escritura. B reconstruyó el valor confirmado usando undo. SELECT FOR UPDATE sí solicitó un bloqueo incompatible y falló con ORA-00054: la frase sobre lectores no se extiende a lecturas que piden bloquear. Evidencia 12-lectura-consistente.

18. **Undo y redo.** DELETE debe permitir reconstruir las filas y entradas eliminadas; INSERT puede deshacerse retirando lo insertado. En este experimento: undo DELETE=3416 KB e INSERT=1128 KB. ROLLBACK modifica bloques y por eso genera redo: 4701 KB al deshacer DELETE. Son medidas de esta carga y sus índices, no proporciones universales. Evidencia 12-undo-y-redo.

19. **Durabilidad.** Tras el COMMIT ordinario síncrono, la garantía depende de que el redo de la transacción esté persistido; no exige haber escrito ya todos sus bloques de datos. El experimento generó 1779 KB de redo, dejó 231 bloques sucios y registró cero bloques DBWn en ese intervalo. Tras checkpoint, el contador de sucios de la tabla quedó a cero y DBWn registró 346 bloques para toda la instancia. Evidencia 13.

20. **Caída de instancia.** El alert log mostró redo scan y redo application: se rehacen cambios necesarios para recuperar los bloques. La recuperación también deshace transacciones no confirmadas. La fila 102 conservó EGRESADO confirmado; la 103 no conservó INACTIVO pendiente. RTO observado 5 s; después se reparó 102 a ACTIVO. Evidencia 14a.

21. **C frente a D.** C restauró todo el volumen: 109 s de restauración y vuelta al estado de la copia. Los 2 s impresos son una ventana temporal aproximada entre fin de copia y fallo, no una cantidad de datos perdidos ni un objetivo RPO acordado. D restauró un datafile y aplicó redo: 10 s de reparación, 11 s desde el fallo, sin pérdida del cambio probado posterior al backup. La PDB se cerró y hubo que reabrirla. Evidencias 14c/14d.

22. **Alert log clasificado.** ORA-01110, ORA-01113 y ORA-63999 se observaron en el contexto del fallo de medio provocado en D; fueron incidentes reales durante la prueba, no un problema activo acreditado al final. Se comprobó además el archivo 26: V$RECOVER_FILE vacío, 16/26 ONLINE y RECOVER=NO. ORA-00202 y ORA-205 corresponden al simulacro B. ORA-00800 Set Priority Failed en LGWR/VKTM es recurrente en este entorno y debe documentarse e investigarse por contexto, no descartarse automáticamente. Evidencias 15-healthcheck y 15-comprobar-recuperacion.

## Simulacro de examen S1–S26

Respuestas razonadas según las opciones del enunciado; no son una clave oficial. Cuando no se ejecutó la operación exacta, se indica.

| Pregunta | Respuesta | Justificación y evidencia |
|---|---|---|
| S1 | B | CF cercano a filas implica muchas transiciones entre bloques; parte E. |
| S2 | A, C | Índice funcional o normalizar el dato de entrada si los emails ya están en minúsculas; D/F. |
| S3 | B | El plan mostró TO_NUMBER sobre CODIGO_POSTAL; F. |
| S4 | B | Bitmap es adecuado para filtros analíticos con poca concurrencia de escritura; D. |
| S5 | B | Se observó INDEX SKIP SCAN sin filtrar la primera columna; D. |
| S6 | B | INVISIBLE permite observar y revertir visibilidad sin reconstruir; G. |
| S7 | A, C | COALESCE reparó acceso y SHRINK recuperó espacio; H. Online no implica cero bloqueo breve. |
| S8 | B | REVERSE distribuye inserciones y pierde el acceso ordenado por rango; H: 4→878 lecturas. |
| S9 | C | Una columna ajena a todas las claves y expresiones indexadas no exige mantener sus entradas por ese cambio; G. El acceso para encontrar filas puede variar. |
| S10 | B | El fan-out determina principalmente la altura junto con el número de entradas; C. |
| S11 | A, C | IOT almacena filas en la estructura de PK y evita el salto al heap; D. |
| S12 | B | Se compararon checkpoints del control file y cabecera; I. Es parte de las comprobaciones de recuperación. |
| S13 | C | CKPT registra checkpoints; DBWn escribe bloques y LGWR redo; I/N. |
| S14 | B, E | V$INSTANCE y V$PARAMETER responden en NOMOUNT; arranque por etapas del Lab 4. |
| S15 | B | La secuencia de cambio pasa por MOUNT. En este equipo ya estaba ARCHIVELOG; L no repitió el cambio de modo. |
| S16 | B | Con el grupo INACTIVE ya archivado, CLEAR LOGFILE recrea el grupo en el escenario indicado. Respuesta teórica: no se borró ningún miembro para probarlo. |
| S17 | A, C | Undo permite lectura consistente y Flashback Query; M. |
| S18 | B | Hay que poder rehacer también los bloques de undo antes de deshacer; M. |
| S19 | A | Para COMMIT síncrono ordinario, el redo está persistido; no exige checkpoint ni archivado; N. |
| S20 | A | Un objetivo menor busca reducir trabajo de recuperación mediante checkpoints más agresivos; respuesta teórica, no se probó 300→30. |
| S21 | B | El archivador bloqueado, por ejemplo por FRA llena, impide reutilización necesaria; L. |
| S22 | B | Si la PDB permanece abierta, aislar el archivo de aplicación con OFFLINE. En D Oracle cerró la PDB y se reparó montada. |
| S23 | B | SYSTEM exige recuperación con la base montada en el escenario de la pregunta; no se provocó pérdida de SYSTEM. |
| S24 | B | En el escenario ordinario del enunciado se restaura una copia consistente y se pierde lo posterior; C demuestra ese método, aunque nuestra base está ARCHIVELOG. |
| S25 | B, D | Aumentar capacidad/retención de undo y evaluar garantía para consultas críticas. La garantía puede hacer fallar escrituras sin espacio. No se provocó ORA-01555. |
| S26 | A | V$RECOVERY_AREA_USAGE desglosa el uso por tipo; L. |

## Tabla de recuperación y límites

Los tiempos son observados; no se fijaron objetivos formales RTO/RPO. No todos los cronómetros tienen el mismo inicio.

| Simulacro | Tiempo observado | Inicio y fin | Pérdida observada / punto recuperado |
|---|---:|---|---|
| A | 5 s | Antes de ABORT hasta CDB/PDB abiertas y healthy | Cambio confirmado conservado; pendiente deshecho. |
| B | 9 s | Antes de parada planificada hasta servicio abierto | Copia sana de control file, sin restaurar datos antiguos. |
| C | 109 s | Ejecución del restaurador, sin incluir toda la preparación | Estado de la copia. Ventana potencial impresa: 2 s, sin medir filas perdidas. |
| D | 11 s desde fallo; 10 s reparación | Borrado del datafile hasta PDB reabierta | Cambio posterior al backup conservado mediante RECOVER. |

## Estado de entrega

Verificación técnica: TODO OK. Tres control files, redo con dos miembros por grupo, FRA persistente de 4 GB y copia RMAN completada. Sin recuperación pendiente en V$RECOVER_FILE. Quedan los controles de publicación, revisión del PR, merge, etiquetas y copia final, que se acreditarán al ejecutarlos. Las notas de ejecución que siguen conservan las medidas y retrospectivas recopiladas durante el laboratorio.


## Notas de ejecución conservadas

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
