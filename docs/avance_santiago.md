# Continuación de Santiago: funciones y consultas independientes

Base de este avance: commit `f209c37d7ee54dcf6f70b9d67f96e749d4bdbdf0`
de la rama `santiago/datos-h1-h5`. Se suma al primer commit de tres archivos.
No aplicar el paquete completo anterior: ese paquete incluía propuestas de esquema
que todavía no se acordaron. Esta continuación no requiere esas propuestas.

## Alcance

| Tarea | Avance entregado | Qué falta para la integración del grupo |
|---|---|---|
| H1 | Se corrige la documentación para que U6 figure como propuesta pendiente, no como campo existente | Revisión del modelo con Renata |
| H2 funciones | Descuento general, neto, total de comprobante, stock de sala y antigüedad | Sol debe usar el mismo contrato monetario en los triggers |
| H2 procedimientos | Se mantienen los del primer commit y se agregan pruebas aisladas | Triggers de estados/renglones y concurrencia real |
| H3 | Estrategia ya entregada en el primer commit | Generador y catálogos del equipo |
| H4 | Cinco índices candidatos, scripts de medición y evidencia preliminar | Datos H3, ajuste de S4 y mediciones finales |
| H5 S9 | Consulta directa con agregaciones separadas | Integración con una vista acordada con Valentina |
| H5 S10–S12 | CTE, subconsulta correlacionada, ventanas, división y anti-join | Probar también con dataset H3 |
| H5 U1–U5 | SQL parametrizable, bloques BEGIN/ROLLBACK independientes | Auditoría y reglas completas de los triggers |
| H5 U6 | Pendiente, sin cambios de esquema | Decisión conjunta para almacenar la excepción del 35 % |

Se conserva la firma `fn_calcular_descuento_cliente(id, monto)` y su resultado
NETO, corrigiendo las tasas anteriores. Las tasas nuevas son 10/20/30 % conforme
a RN-06. Ninguna función busca un campo `descuento_excepcional` inexistente.
No se implementan constraints, triggers, roles ni vistas asignados a otras integrantes.

## Ejecutar las pruebas sin tocar la base de trabajo

Con Node.js/npm instalados, desde la raíz del repositorio:

```powershell
cd tools/validacion_sql
npm ci
npm test
```

El runner crea PostgreSQL embebido en memoria y descarta la instancia al terminar.
No se conecta al Docker ni a la nube. Ejecuta las migraciones existentes necesarias,
las funciones y los procedimientos; comprueba casos correctos, errores y rollback.
También verifica resultados de S9–S12 y U1–U5, no sólo que el SQL se pueda analizar.
Esto no sustituye las pruebas globales de Renata ni las de infraestructura de Sol.

Alternativa en una base PostgreSQL VACÍA y descartable, con conexión psql configurada:

```sh
psql -X -v ON_ERROR_STOP=1 -f database/instalar_santiago.sql
psql -X -v ON_ERROR_STOP=1 -f database/tests/santiago_tests.sql
```

El primer archivo crea el esquema: no ejecutarlo sobre una base existente. El segundo
crea fixtures con IDs negativos reservados y termina con ROLLBACK. Si existe una
colisión, falla sin borrar datos previos. La comprobación de S9 se realiza en el runner.

Para ejecutar consultas sobre un dataset que ya tenga datos:

```sh
psql -X -v vino=1 -v bodega=30123456789 -f consultas/select_avanzadas.sql
psql -X -v bodega=30123456789 -f consultas/update.sql
```

Reemplazar código/CUIT por valores del dataset. U1–U5 hacen ROLLBACK; no convertir
esos ejercicios en actualizaciones de producción por quitar ROLLBACK sin revisión.
U1 recalcula usando las tasas actuales; una lectura histórica normal no lo hace.

## Índices y evidencia

`008_indices.sql` define candidatos a probar, no una mejora garantizada. Las
mediciones en `docs/evidencias/planes_embebido.json` provienen de la prueba
preliminar del 21/10/2026 contra el mismo `001_esquema.sql`, con las mismas consultas
e índices incluidos aquí. No fueron repetidas para esta continuación: la corrección
de descuentos no cambia las consultas del benchmark ni su fixture.

S8 y S5 mejoraron en esa prueba; S4 empeoró. El informe explica el recorrido completo
del detalle y qué debe evaluarse con múltiples vinos del dataset H3. No se declara
H4 completo ni se atribuyen esas mediciones al Docker del equipo.

## Límite de este avance

Se pueden estudiar, revisar y guardar estos archivos en la rama propia. Para
integrarlos como solución completa hay que acordar el contrato de importes con Sol,
la vista S9 y la excepción U6 con Valentina, y las revisiones del modelo con Renata.
La API, el frontend y la nube no se agregan sin el trabajo base de sus responsables.
