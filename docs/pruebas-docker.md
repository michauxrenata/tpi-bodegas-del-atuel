# Prueba de Docker y PostgreSQL

## Proyecto

**Bodegas del Atuel**

## Etapa

**Etapa 1 — Modelado, Hito H1**

## Responsable

**Sol**

## Fecha

**20 de octubre de 2026**

---

## 1. Objetivo

El objetivo de esta prueba es preparar y verificar un entorno reproducible para ejecutar PostgreSQL mediante Docker Compose.

En esta primera instancia se comprueba que:

- Docker Compose pueda iniciar el servicio de PostgreSQL.
- Las variables de entorno sean reconocidas correctamente.
- La base de datos local se cree.
- El contenedor acepte conexiones.
- PostgreSQL quede disponible para ejecutar posteriormente el esquema inicial.

La ejecución definitiva del archivo `001_esquema.sql` queda pendiente hasta que el DER sea revisado, aprobado por el equipo y reflejado en una nueva versión del script.

---

## 2. Archivos utilizados

Para esta prueba se utilizaron los siguientes archivos:

```text
.env
.env.example
.gitignore
compose.yaml
```

### Archivo `.env`

El archivo `.env` contiene las variables locales utilizadas para ejecutar PostgreSQL.

Este archivo no debe subirse al repositorio porque contiene información sensible, como la contraseña local de la base de datos.

### Archivo `.env.example`

El archivo `.env.example` documenta las variables necesarias para configurar el entorno, pero no contiene contraseñas reales.

### Archivo `.gitignore`

El archivo `.gitignore` evita que se suban al repositorio:

- El archivo `.env`.
- Contraseñas.
- Logs.
- Archivos temporales.
- Backups.
- Entornos virtuales.
- Dependencias locales.

### Archivo `compose.yaml`

El archivo `compose.yaml` define el servicio de PostgreSQL, sus variables de entorno, el puerto de conexión, el volumen de datos y el healthcheck.

---

## 3. Requisitos utilizados

Para realizar la prueba se utilizaron:

- Docker Desktop.
- Docker Compose.
- PostgreSQL 16 mediante una imagen oficial de Docker.
- PowerShell.
- Sistema operativo Windows.

La versión utilizada de PostgreSQL cumple con el requisito de la consigna, que solicita PostgreSQL 14 o superior.

---

## 4. Configuración del entorno

El archivo `.env` se creó manualmente en la raíz del repositorio.

La estructura del repositorio quedó organizada de la siguiente manera:

```text
tpi-bodegas-del-atuel/
├── .env
├── .env.example
├── .gitignore
├── compose.yaml
├── database/
└── docs/
```

El archivo `.env` contiene las variables necesarias para crear la base local:

```env
POSTGRES_DB=bodegas_atuel
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CONTRASENA_LOCAL
POSTGRES_PORT=5432
```

La contraseña real utilizada se mantiene únicamente en el archivo `.env` local y no se incluye en este documento ni en el repositorio.

---

## 5. Comandos ejecutados

Los comandos se ejecutaron desde la carpeta raíz del repositorio.

### 5.1. Levantar el contenedor

```powershell
docker compose up -d
```

La opción `-d` permite ejecutar el contenedor en segundo plano.

### 5.2. Verificar el estado del servicio

```powershell
docker compose ps
```

### 5.3. Consultar los logs de PostgreSQL

```powershell
docker compose logs db
```

### 5.4. Ingresar a la base de datos

```powershell
docker compose exec db psql -U postgres -d bodegas_atuel
```

### 5.5. Detener el entorno

```powershell
docker compose down
```

### 5.6. Eliminar el contenedor y el volumen

Para crear nuevamente la base desde cero se puede utilizar:

```powershell
docker compose down -v
```

La opción `-v` elimina el volumen local de PostgreSQL. Debe utilizarse con precaución porque elimina los datos almacenados en ese volumen.

---

## 6. Resultado de la prueba

La primera ejecución produjo advertencias porque el archivo `.env` todavía no había sido creado. Docker Compose no encontró las variables necesarias y mostró mensajes similares a los siguientes:

```text
The "POSTGRES_USER" variable is not set.
The "POSTGRES_DB" variable is not set.
The "POSTGRES_PASSWORD" variable is not set.
The "POSTGRES_PORT" variable is not set.
```

Como consecuencia, PostgreSQL no pudo inicializarse porque no recibió una contraseña para el usuario administrador.

El problema se solucionó creando manualmente el archivo `.env` en la raíz del repositorio y completando las variables necesarias.

Después de crear el archivo `.env`, se reinició el entorno con:

```powershell
docker compose down -v
docker compose up -d
```

Luego se verificó nuevamente el estado mediante:

```powershell
docker compose ps
```

Y se revisaron los logs con:

```powershell
docker compose logs db
```

Después de corregir la configuración, el contenedor inició correctamente y PostgreSQL quedó disponible para aceptar conexiones.

---

## 7. Verificación de la conexión

Se ingresó al contenedor mediante:

```powershell
docker compose exec db psql -U postgres -d bodegas_atuel
```

Dentro de PostgreSQL se ejecutaron las siguientes consultas:

```sql
SELECT current_database();
```

La consulta permitió verificar que la base activa fuera:

```text
bodegas_atuel
```

También se consultó la versión de PostgreSQL:

```sql
SELECT version();
```

La base quedó configurada para utilizar PostgreSQL 16.

Finalmente, se comprobó la existencia de tablas mediante:

```sql
\dt
```

En esta etapa todavía no se ejecutó `001_esquema.sql`, por lo que no se esperaba encontrar las tablas propias del proyecto.

Para salir de la consola de PostgreSQL se utilizó:

```sql
\q
```

---

## 8. Verificación de seguridad del archivo `.env`

El archivo `.env` contiene una contraseña local y no debe subirse al repositorio.

Se verificó que Git lo ignorara mediante:

```powershell
git status
```

También puede comprobarse específicamente con:

```powershell
git check-ignore -v .env
```

El archivo que sí debe subirse al repositorio es:

```text
.env.example
```

El archivo que no debe subirse es:

```text
.env
```

---

## 9. Estado de la ejecución de `001_esquema.sql`

La ejecución definitiva de `001_esquema.sql` todavía no se realizó porque el DER se encuentra actualmente en revisión.

El equipo está evaluando posibles correcciones relacionadas con:

- Entidades.
- Relaciones.
- Claves primarias.
- Claves foráneas.
- Nombres de tablas.
- Nombres de columnas.
- Restricciones.
- Jerarquía de clientes.
- Relaciones muchos a muchos.

Una vez que el DER sea aprobado, se deberá actualizar el archivo:

```text
database/migrations/001_esquema.sql
```

Después se realizará una nueva prueba sobre una base vacía.

El procedimiento previsto será:

```powershell
docker compose down -v
docker compose up -d
docker compose logs db
```

Luego se verificará la creación de las tablas desde PostgreSQL.

---

## 10. Próximos pasos

Una vez que el DER y el esquema inicial sean aprobados, se realizarán las siguientes actividades:

1. Actualizar `001_esquema.sql`.
2. Ejecutar el script sobre una base vacía.
3. Verificar que la creación finalice sin errores.
4. Comprobar la existencia de todas las tablas.
5. Revisar las claves primarias y foráneas.
6. Comparar el esquema físico con el diccionario de datos.
7. Registrar cualquier error encontrado.
8. Coordinar las correcciones con el equipo.
9. Repetir la prueba si fuera necesario.
10. Documentar el resultado definitivo del Hito H1.

---

## 11. Conclusión

La configuración inicial de Docker y PostgreSQL quedó preparada para el desarrollo del proyecto.

Se logró:

- Crear el archivo local `.env`.
- Configurar las variables necesarias.
- Evitar que `.env` sea subido al repositorio.
- Levantar PostgreSQL mediante Docker Compose.
- Crear la base de datos local `bodegas_atuel`.
- Verificar la conexión al contenedor.
- Consultar la versión de PostgreSQL.
- Dejar preparado el entorno para ejecutar el esquema inicial.

La validación definitiva de `001_esquema.sql` queda pendiente hasta que el equipo finalice la revisión del DER y actualice el modelo físico.

Por lo tanto, el resultado actual corresponde a una **prueba exitosa de la infraestructura Docker y PostgreSQL**, pero todavía no constituye la validación final del esquema de la base de datos.