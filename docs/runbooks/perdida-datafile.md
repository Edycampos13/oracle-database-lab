# Pérdida de un datafile de aplicación

## Diagnóstico
Identificar número, ruta y PDB con el error ORA-01110 y el alert log.
Comprobar el estado de la PDB. Conservar evidencias y hora del fallo.
Confirmar ARCHIVELOG, backup RMAN utilizable y redo necesario.

## Recuperación
Este procedimiento corresponde a un datafile de aplicación,
no a SYSTEM, SYSAUX ni undo.

Si la PDB sigue abierta, conectar como SYSDBA a ella y ejecutar:
ALTER DATABASE DATAFILE <numero_verificado> OFFLINE;

Si Oracle cerró la PDB, esperar a que quede MOUNTED antes de reparar.
Desde RMAN conectado a la CDB:
RESTORE DATAFILE <numero_verificado>;
RECOVER DATAFILE <numero_verificado>;

Comprobar que RMAN terminó sin errores.
Desde SYSDBA en la PDB:
ALTER DATABASE DATAFILE <numero_verificado> ONLINE;

Si la PDB estaba montada, abrirla desde la raíz:
ALTER PLUGGABLE DATABASE <pdb_verificada> OPEN;

No abrir con RESETLOGS ni borrar archivos adicionales por ensayo.

## Validación
Comprobar estado READ WRITE, consulta de negocio y cambio confirmado
posterior al backup. Revisar alert log, archivos y FRA.
Registrar RTO desde el fallo y pérdida observada de datos.
Si falta backup o redo, detenerse y evaluar alternativas de recuperación.

## Ejecución de este laboratorio
Archivo 16, TBS_ACADEMIA, FREEPDB1.
RESTORE y RECOVER correctos; fila 104 conservó EGRESADO.
RTO desde el fallo: 11 s. Cambio probado sin pérdida.
Después se devolvió la fila 104 a ACTIVO.
