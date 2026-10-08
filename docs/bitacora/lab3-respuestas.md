# Laboratorio 3 — Respuestas de comprobación

## 8.1.1. Docker

### 1. ¿Qué diferencia hay entre una imagen y un contenedor? Usa como ejemplo lo que hiciste en los ejercicios G2 y G4.

Una imagen es como una plantilla que ya trae todo lo necesario para crear un contenedor. En cambio, el contenedor es una instancia de esa imagen que está creada y puede estar ejecutándose o detenida.

Por ejemplo, en G2 usamos la imagen `hello-world` para crear un contenedor. Ese contenedor ejecutó su proceso, mostró el mensaje y después terminó. En G4 usamos la imagen `alpine:3.20` para crear el contenedor `prueba` y entramos dentro de él con una shell. La imagen seguía siendo la misma, pero el contenedor era una instancia concreta creada a partir de ella.

### 2. En el Ejercicio G5 el archivo nota.txt desapareció y en el G6 no. Explica por qué.

En G5 el archivo se guardó directamente dentro del sistema de archivos del contenedor. Cuando eliminamos ese contenedor y creamos otro nuevo, el archivo ya no existía porque esos datos estaban ligados al contenedor que se borró.

En G6 usamos un volumen de Docker. El archivo se guardó en el volumen y no dentro del contenedor, así que aunque el primer contenedor desapareció, el segundo pudo montar el mismo volumen y seguir viendo `nota.txt`.

### 3. ¿Qué diferencia hay entre docker ps y docker ps -a, y qué significa STATUS = Exited (0)?

`docker ps` muestra solamente los contenedores que están en ejecución en ese momento.

`docker ps -a` muestra todos los contenedores, tanto los que están funcionando como los que ya terminaron.

`Exited (0)` significa que el contenedor terminó y que su proceso principal salió correctamente. El código `0` indica que no hubo error.

### 4. En -p 8181:8181, ¿qué número corresponde a tu equipo y cuál al contenedor? ¿Qué pasaría con -p 80:8080 en el ejercicio de nginx?

En `-p 8181:8181`, el primer `8181` es el puerto de mi equipo y el segundo `8181` es el puerto del contenedor. El formato es `host:contenedor`.

Con `-p 80:8080`, Docker enviaría las conexiones que llegan al puerto 80 de mi equipo hacia el puerto 8080 del contenedor. En el ejercicio de nginx eso no habría funcionado como queríamos, porque nginx estaba escuchando en el puerto 80 dentro del contenedor. Por eso usamos `-p 8080:80`.

### 5. ¿Por qué un contenedor de Oracle se queda en marcha y el de hello-world termina solo?

Porque un contenedor sigue vivo mientras su proceso principal siga ejecutándose.

`hello-world` solamente ejecuta un programa que muestra un mensaje y termina, así que el contenedor también termina.

Oracle, en cambio, mantiene procesos de la base de datos funcionando constantemente para poder aceptar conexiones. Como su proceso principal sigue activo, el contenedor se mantiene en ejecución.

### 6. ¿Qué es el digest de una imagen y por qué lo registramos si ya sabemos que usamos :latest?

El digest es como una huella única de una imagen concreta. Normalmente aparece como `sha256:...`.

Lo registramos porque la etiqueta `latest` puede cambiar con el tiempo. Hoy puede apuntar a una versión y dentro de unos meses a otra diferente. El digest permite saber exactamente qué imagen usamos en el laboratorio aunque `latest` cambie después.

### 7. ¿Qué comando borraría realmente los datos de Oracle? ¿Por qué docker rm oralab-26ai no lo hace?

Para borrar realmente los datos habría que eliminar también el volumen donde Oracle guarda la información, por ejemplo:

`docker volume rm oralab-26ai-data`

`docker rm oralab-26ai` solamente elimina el contenedor. Los archivos de la base están guardados en el volumen persistente, así que mientras ese volumen exista se pueden volver a usar al crear otro contenedor.

---

## 8.1.2. Git, organización y evidencia

### 8. ¿Por qué este laboratorio se hace dentro del repositorio oracle-database-lab, con Issue, branch y Pull Request, en vez de en una carpeta aparte?

Porque no se trata solamente de instalar Oracle, sino también de dejar todo documentado y versionado.

El Issue sirve para definir el trabajo que se va a hacer, la branch permite trabajar sin modificar directamente `main`, y el Pull Request sirve para revisar los cambios antes de integrarlos.

Además, así quedan guardados los scripts, las migraciones y las evidencias de cada paso y cualquier persona puede ver cómo se construyó el entorno.

### 9. ¿Qué diferencia hay entre source 00-config.sh y bash 00-config.sh? ¿Por qué usamos source?

`bash 00-config.sh` ejecuta el archivo en otro proceso de Bash. Cuando ese proceso termina, las variables que se definieron dentro desaparecen.

`source 00-config.sh` ejecuta el contenido dentro de la terminal actual, así que variables como `CONT_NAME`, `EVID`, `IMG` y otras se quedan disponibles.

Por eso usamos `source`, porque necesitamos seguir usando esas variables en los comandos posteriores.

### 10. Explica cada parte del nombre 20260915T091230Z_02-docker.script.log.

`20260915` es la fecha: 15 de septiembre de 2026.

`T091230Z` representa la hora en formato UTC: 09:12:30, y la `Z` indica UTC.

`02` es el número de la evidencia.

`docker` indica a qué parte del laboratorio corresponde.

`script` indica que la evidencia se obtuvo desde una sesión o salida de terminal.

`.log` significa que es un archivo de registro.

Este formato ayuda a ordenar las evidencias y saber cuándo y para qué se generó cada una.

### 11. ¿Para qué sirve .gitattributes y qué error evita?

`.gitattributes` sirve para controlar cómo Git maneja algunos archivos, sobre todo los finales de línea.

En este laboratorio hacemos que los archivos `.sh`, `.sql` y `.md` usen `LF`, que es el formato normal de Linux.

Esto evita problemas como `$'\r': command not found`, que puede aparecer cuando un script creado en Windows usa finales de línea `CRLF` y después se intenta ejecutar en Linux.

### 12. ¿Por qué en este Pull Request elegimos Create a merge commit en lugar de Squash and merge?

Porque en este laboratorio cada commit representa una parte concreta del proceso y tiene valor por sí mismo.

Por ejemplo, hay commits para Docker, las migraciones, Java, ORDS, la verificación final, etc.

Si usáramos `Squash and merge`, todos esos commits se convertirían en uno solo y se perdería ese historial paso a paso. Con `Create a merge commit` se conserva cómo se fue construyendo y verificando el entorno.

---

## 8.1.3. Seguridad

### 13. Describe las cuatro capas de la estrategia de contraseñas (Parte D) y qué pasaría si te saltas la primera.

Las cuatro capas son:

1. Primero añadir `config/.env` al `.gitignore`, para que Git no lo versiona.
2. Tener un archivo `config/.env.example` con nombres de variables y valores de ejemplo, pero sin contraseñas reales.
3. Guardar las contraseñas reales solamente en `config/.env`, de forma local.
4. Cargar esas contraseñas mediante variables de entorno para no escribirlas directamente en los comandos.

Si me salto la primera capa y creo el `.env` antes de ignorarlo, existe el riesgo de que Git lo detecte y termine entrando en un commit con las contraseñas reales. :chatgpt-content-reference{index="1"}

### 14. ¿Por qué no escribimos la contraseña directamente en el comando docker run, aunque el script no se suba a Git?

Porque los comandos que escribimos en la terminal pueden quedar guardados en el historial, por ejemplo en `~/.bash_history`.

Si escribo algo como:

`docker run -e ORACLE_PWD=MiClave123 ...`

la contraseña quedaría guardada en texto plano en el historial.

Usando `$ORACLE_PWD`, en el historial queda el nombre de la variable pero no la contraseña real. :chatgpt-content-reference{index="2"}

### 15. Si descubres tu contraseña en un commit ya publicado, ¿basta con borrarla en un commit nuevo? ¿Qué debes hacer?

No. Si una contraseña ya entró en un commit, sigue existiendo en el historial aunque después la borremos.

Lo primero es considerar esa contraseña comprometida y cambiarla.

Después hay que limpiar el historial de Git o pedir ayuda para hacerlo correctamente. Si ya se publicó en GitHub, también hay que informar del problema y rotar el secreto.

No basta con borrar la línea en otro commit.

---

## 8.1.4. Oracle y herramientas

### 16. ¿Por qué no usamos SPOOL ni @archivo.sql con sqlplus dentro del contenedor, y qué hicimos en su lugar?

Porque si ejecutábamos SQL*Plus dentro del contenedor, las rutas de archivos se interpretaban desde el sistema de archivos del contenedor y no desde nuestro repositorio en Ubuntu.

Por eso no usamos `@archivo.sql` dentro del contenedor para leer los scripts del repositorio.

Lo que hicimos fue enviar el archivo SQL desde Ubuntu hacia SQL*Plus usando la entrada estándar, por ejemplo con:

`docker exec -i ... sqlplus ... < archivo.sql`

Y para guardar las evidencias usamos `tee` desde el sistema anfitrión. Así los archivos quedaban directamente dentro del repositorio.

### 17. ¿Qué hace WHENEVER SQLERROR EXIT SQL.SQLCODE al inicio de V000 y V001, y qué pasaría sin esa línea?

Hace que SQL*Plus termine inmediatamente si ocurre un error SQL y devuelva el código de ese error.

Esto es importante porque el script de Bash puede detectar que la migración falló y detenerse.

Sin esa línea, SQL*Plus podría mostrar un error y continuar ejecutando el resto del archivo. Eso podría dejar la base parcialmente configurada y dar la impresión de que la migración terminó bien cuando en realidad no fue así.

### 18. ¿Qué es una migración y por qué V000 y V001 no se deben editar una vez aplicadas?

Una migración es un archivo que representa un cambio concreto y reproducible en la estructura de la base de datos.

En este laboratorio, V000 crea los tablespaces y usuarios, y V001 crea las tablas de los cinco entornos.

Una vez aplicada una migración, no conviene modificarla porque dejaríamos de saber exactamente qué versión se ejecutó originalmente. Si necesitamos hacer otro cambio, lo correcto sería crear una migración nueva, por ejemplo V002.

### 19. ¿Por qué en SQL Developer se usa el servicio FREEPDB1 y no FREE ni un SID?

Porque `FREEPDB1` es la PDB donde estamos trabajando y donde creamos nuestros usuarios y objetos.

Si usamos `FREE` o un SID podemos terminar conectándonos al contenedor raíz de Oracle, que no es la base de trabajo del laboratorio.

Por eso en SQL Developer configuramos `Service name = FREEPDB1`.

### 20. ¿Qué aporta SQLcl frente a SQL*Plus, y por qué un DBA debe dominar ambas?

SQL*Plus es una herramienta clásica, sencilla y está disponible prácticamente en cualquier instalación de Oracle. Es muy útil cuando trabajamos directamente en servidores o en situaciones donde no tenemos herramientas más modernas.

SQLcl es más moderno y cómodo. Tiene mejor formato de resultados, historial, autocompletado, conexiones guardadas y más herramientas para trabajar en el día a día.

Un DBA debería conocer las dos porque SQLcl es más cómodo para trabajar normalmente, pero SQL*Plus sigue siendo muy común y muchas veces es lo único disponible en un servidor.

---

## 8.1.5. Entorno de trabajo

### 21. ¿Por qué el curso pasa de Git Bash a Ubuntu en WSL 2? Da al menos dos problemas concretos de Git Bash que desaparecen en Ubuntu.

Porque Git Bash es una emulación de un entorno tipo Unix en Windows, mientras que WSL 2 nos da un Linux real.

Un problema de Git Bash es que puede transformar rutas Linux como `/opt/...` en rutas de Windows y eso puede romper argumentos de Docker.

Otro problema es que para algunos comandos interactivos de Docker puede necesitar herramientas como `winpty` o dar errores de TTY.

Además, Git Bash no trae muchas utilidades típicas de administración como `free`, `ss` o `htop`.

En Ubuntu con WSL 2 trabajamos directamente con Linux y esos problemas desaparecen. También estamos usando un entorno mucho más parecido al que encontraríamos en servidores reales. :chatgpt-content-reference{index="3"}

### 22. ¿Por qué clonamos el repositorio en ~/oracle-database-lab y no trabajamos sobre la carpeta de Windows (/mnt/c/...)? ¿Y por qué recomendamos bash frente a zsh para los scripts del curso?

Clonamos el repositorio dentro de `/home`, en `~/oracle-database-lab`, porque así los archivos viven directamente en el sistema de archivos de Linux.

Trabajar sobre `/mnt/c/...` puede ser más lento y también puede dar problemas con permisos y finales de línea porque estamos mezclando el sistema de archivos de Windows con herramientas Linux. :chatgpt-content-reference{index="4"}

Además, usamos `bash` porque todos los scripts del curso están pensados y probados para Bash. Aunque `zsh` es una buena shell para uso interactivo, puede tener diferencias de sintaxis o comportamiento. Usando Bash todos trabajamos con el mismo entorno y es más fácil que los scripts funcionen igual para todos.
