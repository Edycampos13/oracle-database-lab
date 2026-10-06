# Laboratorio 1 - Respuestas

Name: Eduardo Campos Herrera

## 1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository?

El Working Directory es la carpeta donde trabajo y modifico los archivos del proyecto.

La Staging Area es la zona intermedia donde preparo los cambios que quiero incluir en el siguiente commit.

El Local Repository es el historial de commits almacenado por Git en la carpeta .git.

Ejemplo:
Creo o modifico README.md en el Working Directory, ejecuto `git add README.md` para pasarlo a la Staging Area y después ejecuto `git commit` para guardarlo en el Local Repository.

## 2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit?

No. El commit solo incluye los cambios que se encuentran en la Staging Area. Si modifico un archivo pero no ejecuto `git add`, el cambio queda únicamente en el Working Directory y no entra en el siguiente commit.

## 3. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo?

Porque Git versiona archivos, no carpetas vacías. Para conservar las carpetas dentro del repositorio utilizamos archivos `.gitkeep` dentro de ellas.

## 4. Explica con tus palabras qué es HEAD.

HEAD es el puntero que indica en qué commit o branch estoy trabajando actualmente. Por ejemplo, cuando estaba en `feature/customer-search`, HEAD apuntaba a esa rama.

## 5. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G?

`git switch -c` crea una nueva línea de desarrollo dentro del historial de Git, mientras que `mkdir` crea físicamente una carpeta en el disco.

Lo comprobamos cambiando entre `main` y `feature/customer-search`. El archivo `customer-search.md` desaparecía al cambiar a main y reaparecía cuando regresábamos a la branch, sin que se hubiera creado una carpeta física para la branch.

## 6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>?

El contenido entre `<<<<<<< HEAD` y `=======` representaba la versión que ya tenía la branch actual, en nuestro caso main.

El contenido entre `=======` y `>>>>>>>` representaba la versión que venía de la branch que estábamos intentando fusionar.

## 7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?

Porque `git commit --amend` reescribe el último commit y genera un hash diferente. Si ese commit ya fue compartido en GitHub, puede provocar divergencias entre el historial local y el historial de otros colaboradores.

## 8. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?

Se pierde el historial local de Git: commits, branches y configuración del repositorio almacenada dentro de `.git`.

Los archivos del proyecto que están físicamente en el Working Directory no se borran por eliminar `.git`, aunque la carpeta deja de ser un repositorio Git.

## 9. Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".

Git es un programa de control de versiones que utilizo en mi ordenador para crear commits, branches, merges y consultar el historial.

GitHub es una plataforma en Internet donde se pueden alojar repositorios Git y colaborar con otras personas mediante herramientas como Pull Requests, Issues y Code Review.

## 10. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado?

Porque una contraseña o una clave puede quedar almacenada dentro del historial de Git y posteriormente ser vista por personas que obtengan acceso al repositorio. Las credenciales deben mantenerse fuera del control de versiones.

## 11. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con non-fast-forward". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?

Probablemente el repositorio remoto contiene commits que todavía no existen en su repositorio local.

Primero ejecutaría:

`git pull`

Después resolvería cualquier posible conflicto y finalmente volvería a ejecutar `git push`.

## 12. ¿Qué tipo de Conventional Commit usarías para cada caso?

- Añadir un índice de rendimiento a una tabla: `perf`
- Corregir una restricción mal definida: `fix`
- Actualizar el README: `docs`