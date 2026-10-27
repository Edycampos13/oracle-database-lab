WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100
COLUMN name FORMAT A90
COLUMN error FORMAT A35

SELECT file#, online_status, error, change#
FROM v$recover_file;

SELECT file#, con_id, name, status
FROM v$datafile
WHERE file# IN (16, 26);

SELECT file#, con_id, status, error, recover, fuzzy
FROM v$datafile_header
WHERE file# IN (16, 26);

SELECT name, open_mode FROM v$pdbs;
EXIT
