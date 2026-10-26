WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 240 PAGESIZE 100
COLUMN ejemplo_sql FORMAT A100

ALTER SESSION SET CONTAINER = FREEPDB1;

SELECT force_matching_signature,
       COUNT(*) AS cursores_hijos,
       COUNT(DISTINCT sql_id) AS sentencias_distintas,
       SUM(executions) AS ejecuciones,
       MIN(SUBSTR(sql_text, 1, 100)) AS ejemplo_sql
FROM v$sql
WHERE force_matching_signature <> 0
GROUP BY force_matching_signature
HAVING COUNT(DISTINCT sql_id) > 50
ORDER BY sentencias_distintas DESC;

EXIT
