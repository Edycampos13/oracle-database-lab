WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 180 PAGESIZE 100 FEEDBACK ON
COLUMN name FORMAT A24
COLUMN value FORMAT A80
COLUMN file_name FORMAT A100

ALTER SESSION SET CONTAINER = FREEPDB1;

PROMPT == 1. Configurar el destino OMF en memoria y de forma persistente ==
ALTER SYSTEM SET db_create_file_dest =
  '/opt/oracle/oradata/FREE/FREEPDB1' SCOPE = BOTH;

SELECT name, value FROM v$parameter
WHERE name = 'db_create_file_dest';

PROMPT == 2. Crear un tablespace de prueba sin indicar nombre de archivo ==
CREATE BIGFILE TABLESPACE tbs_lab4_omf
  DATAFILE SIZE 10M AUTOEXTEND OFF;

SELECT tablespace_name, file_name
FROM dba_data_files
WHERE tablespace_name = 'TBS_LAB4_OMF';

PROMPT == 3. Eliminar exclusivamente el tablespace de prueba ==
DROP TABLESPACE tbs_lab4_omf INCLUDING CONTENTS AND DATAFILES;

SELECT COUNT(*) AS tablespaces_prueba_restantes
FROM dba_tablespaces
WHERE tablespace_name = 'TBS_LAB4_OMF';

EXIT
