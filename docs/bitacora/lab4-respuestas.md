# Lab 4 — Respuestas basadas en la ejecución

Fecha de ejecución: 26 de octubre de 2026. Oracle Free 23.26.3.0.0, Docker Desktop y WSL2. Las referencias E00–E16 corresponden a los archivos de `docs/bitacora/lab4/evidencia/` cuyo nombre contiene el número de parte y el sufijo indicado. Los valores citados permiten localizar la evidencia sin depender de números de línea.

## Preguntas de comprobación

1. **Consistencia de la copia.** Se realizó `SHUTDOWN IMMEDIATE` antes de copiar el volumen: las transacciones pendientes se deshacen y la base se cierra limpiamente. Copiar archivos de una base abierta con `tar` no garantiza una instantánea coherente ni constituye por sí solo un respaldo online recuperable. Evidencia E00, `00-backup-lab3.script.log`.

2. **Manifiesto e integridad.** `manifiesto.txt` identifica fecha, imagen, volumen, commit y cobertura. `SHA256SUMS` permite detectar cambios o corrupción en los archivos copiados. El restaurador comprueba la integridad antes de sustituir los datos. La verificación E16 confirmó el respaldo íntegro `20261026T161404Z_lab3-final`.

3. **RPO y RTO.** RPO es el objetivo de pérdida máxima admisible de datos; RTO es el objetivo de tiempo de recuperación. Restaurar únicamente mi copia en frío devuelve la base al estado cerrado de esa copia: se perderían los cambios posteriores. Su carpeta se llama `20261026T161404Z_lab3-final` (la marca indica el inicio del proceso, no el instante exacto del cierre). No he definido objetivos numéricos ni medido una restauración; el RTO observado está pendiente. Los 20 segundos hasta `healthy` del arranque tras copiar no son un RTO de restauración.

4. **Rutas de V000.** Los nombres relativos se resolvieron bajo `$ORACLE_HOME/dbs`, por ejemplo `academia01.dbf`. En esta imagen esa carpeta enlazaba con `/opt/oracle/oradata/dbconfig/FREE/dbs`: estaban dentro del volumen, aunque fuera de la carpeta estándar. `DB_CREATE_FILE_DEST`, junto con creación mediante OMF sin nombre explícito de datafile, evita depender de rutas relativas. E01, `01-diagnostico-inicial.script.log`.

5. **RENAME no copia.** `ALTER TABLESPACE ... RENAME DATAFILE` actualiza la ruta conocida por Oracle; no traslada físicamente el archivo. El procedimiento ejecutado fue OFFLINE NORMAL, copia física, RENAME y ONLINE. E03, `03-reubicar-datafiles.script.log`.

6. **Migración nueva.** V000 ya aplicada debe conservar su historial reproducible. V003 documenta una corrección posterior. Quitar una contraseña del archivo no la elimina de commits antiguos; `NO AUTHENTICATION` invalida el inicio de sesión de esos propietarios. E04, V003; E16: cero cuentas ADMIN_* con contraseña.

7. **Persistencia.** Tras eliminar y recrear el contenedor, permanecieron los cinco tablespaces ONLINE y las tablas de los esquemas. La prueba se hizo tras comprobar las rutas para no depender de archivos en la capa efímera del contenedor. También desapareció la publicación de 8181. E03, `03-prueba-persistencia.script.log`.

8. **Instancia y base.** Instancia: host `979ebb9617bc`, estado OPEN/ACTIVE y arranque `2026-10-26 17:06`. Base: nombre FREE, DBID 1509902213 y modo ARCHIVELOG. El arranque pertenece a la ejecución de procesos y memoria; la identidad de la base pertenece a sus archivos. E15, sección 1.

9. **Etapas.** NOMOUNT lee SPFILE/PFILE y crea memoria y procesos; V$DATABASE da ORA-01507 porque aún no hay montaje. MOUNT abre control files y conoce datafiles y redo. Consultar el diccionario antes de OPEN produce ORA-01219. OPEN abre los archivos necesarios para el uso normal. FREEPDB1 se abrió automáticamente con su estado guardado. E06, `06-arranque-por-etapas.script.log`.

10. **Memoria frente a SPFILE.** V$PARAMETER mostraba `db_files=200` mientras V$SPPARAMETER mostraba 300 tras SCOPE=SPFILE. El valor pendiente no se aplicaba hasta reiniciar. RESET retiró esa entrada: quedó 200 en memoria y no especificado en SPFILE. E07, `07-parametros-cambios.script.log`.

11. **PROCESSES.** En mi versión la vista mostraba IMMEDIATE, pero el intento real con SCOPE=MEMORY fue rechazado con ORA-02097 y ORA-02095. No basta esa etiqueta para concluir que el cambio concreto está permitido: se debe comprobar el comportamiento y la documentación de la versión. El experimento no dejó un aumento aplicado. E07.

12. **Gestión de memoria.** La SGA usa ASMM: `sga_target=1536M`, `memory_target=0` y `memory_size=0`. La PGA se gestiona con objetivo `pga_aggregate_target=512M` y límite `pga_aggregate_limit=2G`. `db_cache_size=0` no significa ausencia de caché: no se fijó un mínimo explícito para ese componente. E08, `08-memoria.script.log`.

13. **Caché.** Ronda fría: 465 lecturas lógicas y 258 físicas. Caliente: 247 lógicas y cero físicas, ambas con 17 600 filas ACTIVO. En caliente no hubo lecturas físicas de Oracle. La fórmula simplificada 1−físicas/lógicas da 44,5 % y 100 %, pero el primer valor incluye trabajo interno y no debe interpretarse como una tasa pura de aciertos de los bloques de la tabla. E08, `08-experimento-cache.script.log`.

14. **Literales y bind.** Literales: 1072 análisis totales, 1008 duros y 4390 ms; bind: 1 análisis total, 1 duro y 20 ms. V$SQL conservaba 425 cursores de literales frente a 1 cursor con 1000 ejecuciones para bind. El trabajo recursivo puede añadir análisis y la caché puede expulsar cursores. E08, `08-parse-y-pga.script.log`.

15. **SPID y PID.** LGWR tenía SPID 1611 y `/proc` mostraba PID 1611 para `db_lgwr_FREE`. `docker top` observa el espacio de PID del host, de modo que puede mostrar otro número para el mismo proceso. E09 SQL y `09-procesos-so.script.log`.

16. **Visibilidad multitenant.** SYS en la raíz veía 4 datafiles de CON_ID 1, 3 de CON_ID 2 y 9 de CON_ID 3: total 16. Dentro de FREEPDB1 solo veía sus 9 datafiles. E10, `10-que-ve-cada-usuario.script.log`.

17. **ORA-00942.** LAB4_ANALISTA solo tenía CREATE SESSION; DBA_TABLES no estaba accesible para él. Oracle respondió que la tabla o vista no existe en su ámbito de acceso, sin revelar su contenido. E10, sección 3.

18. **CONTAINER_DATA.** C##LAB4_AUDITOR podía consultar el catálogo y cambiar de contenedor, pero desde la raíz solo veía los datos permitidos de CON_ID 0 y 1. C##OPS_RO tenía CONTAINER_DATA para todos. Para igualar esa visibilidad desde la raíz: `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`. Eso no iguala automáticamente otros permisos puntuales. E10, secciones 5–6.

19. **Permiso de esquema.** READ ANY TABLE ON SCHEMA evita conceder tabla por tabla e incluye nuevas tablas del esquema. El riesgo es permitir también el acceso a futuros datos sensibles de ese esquema. No concede UPDATE ni lectura de otros esquemas. E10: pudo contar 20 000 estudiantes, pero recibió ORA-41900 al actualizar y ORA-00942 en Clínica.

20. **Prefijo real.** COMMON_USER_PREFIX valía `C##`; crear LAB4_LOCAL en CDB$ROOT produjo ORA-65096. No se creó como usuario común. E10, `10-ciclo-vida-pdb.script.log`, sección 3.

21. **Archivos.** Base: datafiles, control files y online redo; los tempfiles sostienen el almacenamiento temporal y se recrean. Relacionados: archived redo, SPFILE, password file y ADR. El password file permite autenticar conexiones administrativas remotas; no contiene tablas de negocio. V$PASSWORDFILE_INFO indicó `$ORACLE_HOME/dbs/orapwFREE`. Su ruta física resuelta debe verificarse con readlink, pues la sección 2 del inventario Linux quedó vacía. E11.

22. **Tamaño físico.** 100 MiB = 104 857 600 bytes; Linux mostró 104 865 792. La diferencia de 8192 bytes corresponde al bloque adicional de cabecera del archivo frente al tamaño informado para el datafile. E11, inventarios SQL/Linux.

23. **Puntos de fallo.** Los dos control files estaban en el mismo volumen, así que no proporcionaban independencia ante pérdida de ese almacenamiento. Cada uno de los tres grupos de redo tenía un solo miembro. Añadir copias en el mismo disco protege de ciertos fallos de archivo, no de perder el disco completo. E11/E15.

24. **ADR efímero.** Al recrear el contenedor se pierde la historia de diagnóstico aunque los datos persistan. Se debe persistir el ADR o recoger los logs externamente. E11, `11-archivos-so.script.log`: ADR fuera del volumen.

25. **ROWID.** `AAAR2uAAAAAAAMOAAF`: objeto 73134, archivo absoluto 16, bloque BIGFILE 782, slot 5. DBA_OBJECTS lo relacionó con ADMIN_ACADEMIA.ACA_ESTUDIANTES y DBA_DATA_FILES con academia01.dbf. El archivo relativo era 1024; no debe confundirse con el número absoluto. E12, `12-bloque.script.log`.

26. **Cabecera.** nrow=90 es el número de entradas de fila. fsbo es el inicio del espacio libre y fseo su final; avsp representa espacio libre disponible. En este bloque: 0x427−0xc6=0x361, es decir 1063−198=865 bytes, igual a avsp. E12.

27. **ITL y limpieza diferida.** La entrada tenía Lck=90 y Flag --U-. Refleja información de la transacción que afectó esas filas y del commit pendiente de limpieza completa de las marcas del bloque; no demuestra por sí sola 90 bloqueos activos actuales. El delayed block cleanout completa esa información al volver a acceder al bloque, evitando recorrer todos los bloques modificados en cada COMMIT. E12.

28. **Longitud física.** Datos: 3+9+9+11+19+6+11=68 bytes. Siete indicadores de longitud de un byte más cabecera de fila de tres bytes: 68+7+3=78, que coincide con `tl: 78`. La entrada del directorio de filas es aparte. E12.

29. **Factor de bloqueo.** bfr=floor((8192−96)×0,9/76)=95; b=ceil(20000/95)=211. El ajuste del script para cabecera de 122 bytes y dos bytes de directorio da bfr=93 y 216 bloques. La ocupación real no es uniforme: 231 bloques con filas, media 86,6; 244 bajo la HWM y 256 asignados. Las fórmulas no modelan todo el espacio de gestión, la variación de longitudes ni el llenado real. E13.

30. **Costes medidos.** Lectura lógica: 6,98 µs de CPU. Física aleatoria: 38,2 µs de tiempo transcurrido por bloque, incluyendo trabajo de la consulta. Secuencial: 128,3 ms/4595≈27,92 µs por bloque, con unos 280 MiB/s. No son magnitudes idénticas: la primera mide CPU y las otras tiempo transcurrido. E13.

31. **Umbral con HDD.** Usando 150 MiB/s, el bloque de 8192 bytes cuesta 0,05208 ms secuenciales. Con latencia aleatoria de 5 ms y bfr=86: (1/86)×(0,05208/5)=0,0001211, es decir aproximadamente 0,0121 % de las filas. Si MB se interpreta decimal, resulta aproximadamente 0,0127 %. Es una estimación simplificada, no una regla universal del optimizador. E13, fórmula 5d.

32. **Caché del sistema operativo.** FLUSH BUFFER_CACHE vacía la caché de Oracle, no la caché de páginas Linux. Una lectura física contabilizada por Oracle puede resolverse en RAM del sistema operativo. El método sigue siendo útil para comparar, pero esas cifras no son una medida de latencia del dispositivo físico. E13.

33. **Migración y encadenamiento.** Migración: una fila que cabía crece y se traslada, conservando una cabeza con puntero. Encadenamiento: sus piezas necesitan varios bloques, como la fila de unos 12 KB. Se observan con ANALYZE/LIST CHAINED ROWS, contadores y volcado; CHAIN_CNT no distingue por sí solo ambas causas. MOVE y espacio para crecimiento corrigen la migración; la fila demasiado grande requiere rediseño o bloques adecuados. E14.

34. **3,2 lecturas.** Sobre una base de tres lecturas por búsqueda, el 20 % de filas migradas requiere otra: 3+0,20×1=3,2. Las 1000 búsquedas sumaron 3200 lecturas y 200 `table fetch continued row`. E14.

35. **Índice UNUSABLE.** MOVE cambia las ubicaciones/ROWID de las filas; el índice del experimento quedó UNUSABLE hasta REBUILD. En producción se planifica la indisponibilidad o se utiliza una modalidad que mantenga los índices y permita concurrencia, si la edición y versión la soportan. No debe suponerse que MOVE ONLINE esté disponible en esta edición Free. E14: UNUSABLE→VALID y CHAIN_CNT=0.

36. **Hallazgos propios.** (a) ARCHIVELOG sin FRA: organizar destino, espacio y copias; prioridad alta. (b) Un miembro por grupo de redo y control files en el mismo volumen: multiplexar y planificar independencia del almacenamiento; alta. (c) ADR fuera del volumen: persistir o centralizar diagnóstico; media. El informe lab4-autopsia.md amplía riesgos y evidencias. E15/E11.

37. **Observabilidad de mínimo privilegio.** C##OPS_RO separa la consulta del catálogo de las tareas administrativas. No recibe DBA ni permisos de escritura ANY; no puede administrar la base ni modificar datos por los permisos otorgados. No se debe usar SYSTEM para un informe rutinario. E16 verifica ausencia de privilegios ANY de escritura y E11 el GRANT SELECT puntual.

38. **Exposición corregida.** V003 invalida las contraseñas de propietarios que habían quedado en migraciones/historia. Los nuevos wrappers evitan pasar contraseñas como argumentos visibles de procesos; SYSDBA usa autenticación del sistema operativo y SQLcl recibe la credencial por entrada estándar. La comprobación de secretos antes de publicar sigue pendiente y debe incluir la historia existente.

## Preguntas tipo examen

Las letras corresponden a las opciones del enunciado v3. Son respuestas razonadas, no una clave oficial del docente.

| Pregunta | Respuesta | Justificación |
|---|---|---|
| P1 | A, D | Una copia completa tras cierre limpio es consistente y puede abrirse sin recuperación; E00. |
| P2 | B | OFFLINE, copia física, RENAME y ONLINE; E03. |
| P3 | A, C | STARTUP_TIME cambia al arrancar; CREATED corresponde a la creación de la base; E05. |
| P4 | A, C | NOMOUNT permite consultar parámetros y crear el control file; E06. |
| P5 | B | El cambio de modo de archivado requiere MOUNT. |
| P6 | B | Con SPFILE, el SCOPE implícito de ese cambio es BOTH; E07. |
| P7 | C | PROCESSES no se cambia desde una PDB: ORA-65040; E07. |
| P8 | A, C | Se arranca con PFILE válido y se recrea el SPFILE. |
| P9 | B | ASMM reparte la SGA respetando el mínimo explícito del buffer cache. |
| P10 | A, D | La ordenación y memoria de sesión dedicada pertenecen a la PGA; E08. |
| P-G1 | B | Variables de enlace para compartir el cursor; 1008 frente a 1 hard parse; E08. |
| P-G2 | B | El área de trabajo necesitó varias pasadas por TEMP; E08: 6 PASSES y 3072 KB. |
| P11 | C | El COMMIT ordinario espera la persistencia de su redo mediante LGWR. |
| P12 | B, D | PMON y SMON son procesos básicos de la instancia; E09. |
| P13 | B | Dentro de FREEPDB1 se ve CON_ID 3; E10. |
| P14 | B | CONTAINER_DATA amplía la visibilidad desde la raíz; E10. |
| P15 | A, D | El permiso cubre nuevas tablas de HR, no otros esquemas; E10. |
| P16 | B, D | Control files y online redo son archivos de la base; E11. |
| P17 | C | La pérdida descrita en NOARCHIVELOG obliga a restaurar la copia completa disponible. |
| P18 | B | Es necesario indicar BIGFILE al decodificar el bloque del ROWID; E12. |
| P19 | A, B | PCTFREE reserva espacio para el crecimiento de filas mediante UPDATE. |
| P20 | B | bfr=floor(8096×0,9/180)=40; ceil(2000000/40)=50000. |
| P21 | B | Scattered read representa lecturas multibloque al buffer cache. |
| P22 | A, C | Se identifican filas y se reorganiza con espacio para crecer, verificando disponibilidad de MOVE ONLINE. |
| P23 | B | La fila supera el bloque: encadenamiento que MOVE no elimina; E14. |
| P24 | B | Cuenta de observabilidad con permisos de catálogo y GRANT puntual; E11/E16. |
| P25 | B | PDB$SEED es la plantilla de solo lectura; E10. |
| P26 | C | C## no es válido para un usuario local con ese prefijo configurado; E10. |
| P27 | B | Cerrar antes de DROP INCLUDING DATAFILES; E10. |
| P28 | A, C | V$DATAFILE y V$LOG pueden consultarse con la base montada. |
| P29 | A | KCC corresponde a estructuras del control file. |
| P30 | B | Las CDB_ existen también dentro de PDB, limitadas a su ámbito; E10. |
| P31 | B | Los tempfiles se recrean y no se respaldan como datafiles. |
| P32 | B | La configuración activa permanece en memoria; se puede reconstruir el SPFILE. |
| P33 | B | V$PWFILE_USERS enumera usuarios y privilegios del password file; E11. |
| P34 | A, B | ITL y directorio de filas son estructuras de cabecera del bloque; E12. |
| P35 | B | Se observaron extensiones de 64 KB y después de 1 MB; E12. |
| P36 | B | AUTO indica ASSM, gestión mediante mapas de bits. |
| P37 | B | Es la configuración BIGFILE local del escenario del enunciado; comprobar el valor predeterminado de la base al generalizar. |
| P38 | A | Hay accesos lógicos sin lecturas físicas: los bloques solicitados estaban en caché. |
| P39 | A, B | Más espacio reservado y filas mayores reducen filas por bloque; E13. |
| P40 | B | Vaciar el buffer cache provoca recalentamiento y puede elevar la latencia de otras sesiones. |
| P41 | B | La migrada se desplazó al crecer; la encadenada del ejemplo supera un bloque; E14. |
| P42 | A | REBUILD recupera el índice; una alternativa online depende de edición/versión; E14. |
| P43 | A | V$DIAG_ALERT_EXT permite leer el alert log; E11. |
| P44 | A, B | Revisar crecimiento y ampliar capacidad según el tipo de tablespace. |
| P45 | A, B | Las PDB comparten SGA, background y online redo. |
| P46 | B | Se observó ORA-01031 con el usuario local; E10. |

## Estado y límites de la entrega

La verificación técnica E16 terminó TODO OK. Esto no acredita por sí solo el cierre documental, la revisión del PR ni los retos adicionales. RTO de restauración no medido. Comprobación de secretos, commits por partes, Issue, PR, revisión y etiquetas pendientes al redactar este archivo.

Retos prácticos adicionales no acreditados con evidencia en esta conversación: configuración OMF persistente, diagnóstico por force_matching_signature, captura simultánea de sesión de mayor consumo y volcado de otro estudiante. No se presentan como realizados.

## Actualización de la respuesta 21

La comprobación con readlink confirmó que el SPFILE y el password file
están dentro del volumen, bajo /opt/oracle/oradata/dbconfig/FREE/dbs/.
Es la carpeta dbs completa la que está enlazada.
Evidencia: script/*_11-rutas-configuracion.script.log.

## Reto OMF completado

En FREEPDB1 configuré DB_CREATE_FILE_DEST con SCOPE=BOTH a
/opt/oracle/oradata/FREE/FREEPDB1.
Al crear TBS_LAB4_OMF sin nombre explícito de datafile, Oracle generó
un archivo OMF bajo ese destino. Después eliminé el tablespace:
TABLESPACES_PRUEBA_RESTANTES=0.
La configuración permanece para futuras creaciones que omitan
el nombre del archivo; no corrige rutas explícitas incorrectas.
Evidencia: script/*_03-reto-omf.script.log.

## Reto de detección de literales completado

La consulta agrupada por FORCE_MATCHING_SIGNATURE encontró una familia
con 701 SQL_ID distintos y 701 cursores hijos. EJEMPLO_SQL contenía
SELECT /* lab4_literal */, lo que identifica la consulta del experimento.
Contar SQL_ID distintos permite distinguir textos diferentes de varios
cursores hijos del mismo texto. El recuento refleja los cursores presentes
en caché en ese momento, no todo el historial de ejecuciones.
Evidencia: script/*_08-reto-literales.script.log.

## Reto de observación simultánea completado

Desde una segunda terminal, C##OPS_RO observó la carga de lectura
identificada con MODULE=LAB4_RETO_SESION.
La sesión estaba ACTIVE: SID=57, SERIAL#=37711 y SPID=6414.
Su PGA usada era 1,94 MB y la asignada 2,12 MB.
SQL_ID=gp5nd3q0yxju1 coincidió con:
SELECT SUM(MOD(MATRICULA_ID, 97))
FROM ADMIN_ACADEMIA.ACA_MATRICULAS.
La captura identifica la sesión de prueba, sin acreditar que fuera
la de mayor consumo global.
Evidencia: script/*_09-reto-observar.script.log.
