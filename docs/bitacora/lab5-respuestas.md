
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
