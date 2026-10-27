WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 180 PAGESIZE 100
COLUMN member FORMAT A55

ALTER SYSTEM SWITCH LOGFILE;

SELECT group#, sequence#, members, status
FROM v$log ORDER BY group#;

SELECT group#, member, status
FROM v$logfile ORDER BY group#, member;

EXIT
