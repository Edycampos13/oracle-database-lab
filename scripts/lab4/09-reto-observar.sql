WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 220 PAGESIZE 100
COLUMN module FORMAT A20
COLUMN sql_text FORMAT A85

SELECT s.sid, s.serial#, s.status, s.sql_id,
       p.spid,
       ROUND(p.pga_used_mem / 1048576, 2) AS pga_usada_mb,
       ROUND(p.pga_alloc_mem / 1048576, 2) AS pga_asignada_mb,
       s.module
FROM v$session s
JOIN v$process p ON p.addr = s.paddr
WHERE s.module = 'LAB4_RETO_SESION'
ORDER BY p.pga_used_mem DESC;

SELECT sql_id, SUBSTR(sql_text, 1, 85) AS sql_text
FROM v$sql
WHERE UPPER(sql_text) LIKE '%SUM(MOD(MATRICULA_ID, 97))%';

EXIT

EXIT
