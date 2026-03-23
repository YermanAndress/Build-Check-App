# Build-Check

* [Repositorio del Backend (Spring Boot)](https://github.com/YermanAndress/Build-Check)

## Reglas De Colaboración Segun El Modelo **GitFlow**

### 1. Estructura de Ramas
* **`main`**: Reservada exclusivamente para versiones estables y producción.
* **`develop`**: Rama principal de integración. Todo el código nuevo debe converger aquí.
* **`feature/`**: Ramas temporales creadas para desarrollar una funcionalidad específica (ejemplo: `feature/ocr-camera`). Nacen de `develop`.
* **`hotfix/`**: Ramas de emergencia para corregir errores críticos en la rama `main`.
* **`release/`**: Rama de preparación para una entrega oficial (ejemplo: release/v1.0). Permite realizar pruebas finales y correcciones menores sin detener el desarrollo de nuevas funciones en develop.

### 2. Ciclo de Trabajo Detallado

Para mantener el orden en el repositorio, se seguiran estos tres flujos de trabajo según la necesidad de los cambios a realizar

#### A. Desarrollo Diario (`feature/`)
Es el flujo estándar para agregar funcionalidades o corregir errores menores durante el desarrollo.

1.  **Sincronizar Local:** Asegúrate de tener lo último de la rama de integración.
    ```bash
    git checkout develop
    git pull origin develop
    ```
2.  **Crear O Revisar Rama En Jira:** Crea tu rama de trabajo usando el metodo desde jira.

3.  **Desarrollar:** Realiza tus cambios y crea commits con frecuencia usando los prefijos del Estándar de Commits.

4.  **Subir y Solicitar PR:** Envía tu rama a GitHub usando el commit que te especifica jira y abre un Pull Request (PR) apuntando hacia la rama **`develop`**.
    ```bash
    git add . 
        # Ejemplo: git commit -m "BC-X Tarea Asignada Desde El Backlog"
    git push origin feature/nombre-de-la-tarea
    ```
5.  **Limpieza:** Una vez que el PR sea aprobado y fusionado en GitHub, elimina la rama en tu PC.
    ```bash
    git checkout develop
    git pull origin develop
    git branch -D feature/nombre-de-la-tarea # Recuerda Hacer Referencia al nombre completo de la rama, (ejemplo: git branch -d feature/nombre-de-tu-tarea) 
    ```

#### B. Preparación de Entrega (`release/`)
Se utiliza cuando el código en `develop` está listo para una entrega o revisión.

1.  **Crear Rama de Salida:** Una vez se termine un sprint o sea hora de una revision y se le asigna el ticket desde el jira.
    ```bash
    git checkout -b release/v1.0
    ```
2.  **Ajustes Finales:** Solo se permiten correcciones de errores de último minuto o cambios en documentación.
3.  **Cierre de Release:** Se deben abrir **dos Pull Requests** desde esta rama haciendo el commit explicado anteriormente:
    ```bash
        # Ejemplo: git commit -m "BC-X Tarea Asignada Desde El Backlog"
    ```
    * **Hacia `main`:** Para la versión estable de entrega.
    * **Hacia `develop`:** Para asegurar que los ajustes finales no se pierdan en la rama de integración.

#### C. Correcciones Críticas (`hotfix/`)
Solo se usa si se detecta un error grave en la rama `main` que debe repararse inmediatamente.

1.  **Crear desde Producción:**
    ```bash
    git checkout main
    git checkout -b hotfix/descripcion-error
    
    ```
2.  **Cierre de Hotfix:** Al igual que la release, se deben abrir PRs hacia **`main`** y hacia **`develop`** haciendo el mismo metodo de jira para mantener ambos entornos actualizados y el jira sincronizado correctamente.
    ```bash
        # Ejemplo: git commit -m "BC-X Tarea Asignada Desde El Backlog"
    ```

### 3. Pull Requests (PR) y Revisión
La integración de cualquier código a la rama `main` y `develop` se hará mediante Pull Requests en GitHub:
* **Jira:** Las ramas que se dirijan hacia main y develop tendran que ser creadas y trazabilidazadas de la forma que se explico anteriormente para asi poder tener orden y control en el control de los commits e historias de usuario.
* **Revisión Obligatoria:** Al menos un compañero del equipo debe revisar el código y aprobar el PR.
* **Resolución de Conflictos:** Si existen conflictos el autor de la rama es responsable de resolverlos en su local antes de hacer el Merge.
* **Limpieza:** Una vez aceptada y fusionada la rama, debe ser eliminada para mantener el repositorio limpio.

### 4. Estándar de Commits
Se usaran los prefijos para identificar rápidamente de que se trata el cambio:
* `feat:` Nueva funcionalidad para el sistema.
* `fix:` Corrección de un error o bug.
* `docs:` Cambios solo en la documentación del proyecto.
* `refactor:` Mejora del código sin cambiar su funcionalidad.
* `style:` Cambios de formato (espacios, indentación) que no afectan la lógica.