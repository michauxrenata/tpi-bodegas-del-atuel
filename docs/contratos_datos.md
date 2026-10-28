# Contratos de integración de los SQL de Santiago

## Funciones e importes

| Función | Resultado |
|---|---|
| fn_descuento_cliente(id) | tasa decimal: 0.10 / 0.20 / 0.30 |
| fn_calcular_descuento_cliente(id, monto) | monto NETO, mantiene firma histórica |
| fn_stock_sala(sala, vino) | botellas, cero si no existe fila |
| fn_total_comprobante(numero) | suma de subtotales NETOS históricos |
| fn_antiguedad_anios(fecha [, referencia]) | años completos; referencia por defecto hoy |

Cada renglón: bruto = cantidad × precio_unitario; descuento = ROUND(bruto × tasa, 2);
subtotal = bruto − descuento. Cabecera: subtotal = suma de brutos; descuento = suma
de descuentos; total = suma de netos. Se redondea por renglón. Cambiar un precio o
un descuento del cliente no modifica comprobantes anteriores. U1 sí lo hace como
operación explícita, dentro de pruebas con ROLLBACK.

`STABLE` se usa cuando se leen tablas o CURRENT_DATE; `IMMUTABLE` sólo en el cálculo
con dos fechas explícitas. Ninguna función de lectura adquiere bloqueos de venta.
Los errores de ID ausente usan P0002; argumentos inválidos 22023; reglas 23514.

## Procesamiento de documentos

Los procedimientos reciben un ID, bloquean la cabecera con FOR UPDATE, exigen
`terminado`, verifican renglones y procesan vinos en orden ascendente. Ingresos
suman por UPSERT; transferencias bloquean cada stock de depósito, rechazan tanto
fila ausente como cantidad insuficiente, descuentan y suman a la sala por UPSERT.
El estado sólo cambia al final. Una segunda llamada falla; no vuelve a mover stock.
Cualquier error se propaga y revierte los efectos del CALL. No hay COMMIT interno.

**Protección temporal:** como el repositorio todavía no tiene RN-12, se toma
`LOCK TABLE renglon_* IN SHARE MODE` antes de procesar. Bloquea cambios concurrentes
de renglones de TODA esa tabla hasta terminar la transacción. No impide que un
usuario edite un documento procesado después del COMMIT: eso requiere el trigger
RN-12 de Sol. No es un reemplazo del control de estados ni de los permisos.

Al integrar RN-12, el trigger debe bloquear la cabecera antes de comprobar estado,
incluidas las cabeceras OLD y NEW si cambia de documento. Recién entonces se podrá
retirar el bloqueo global, con una prueba concurrente que demuestre que un renglón
no puede entrar después de haber leído los detalles del procedimiento.

No mezclar escritura de renglones y CALL en transacciones simultáneas largas:
los upgrades de bloqueos pueden producir deadlock. La API debe reintentar la
transacción completa ante 40P01/40001, con límite. READ COMMITTED alcanza con los
bloqueos indicados para dos procesamientos del mismo stock; falta medirlo en servidor.

## Coordinación con Sol y Valentina

- Los triggers de estados validan transiciones; NO vuelven a mover stock cuando
  ven `procesado`: el procedimiento ya lo hizo.
- El trigger de venta debe validar/bloquear stock y calcular precio/bonificación,
  con mantenimiento de cabecera para INSERT, UPDATE y DELETE. El trigger actual
  sólo valida cantidad positiva; RN-08/RN-09 aún no están completas.
- U3 y U5 necesitan el trigger de auditoría RN-13 para cumplir la trazabilidad.
- Las constraints avanzadas y roles siguen pendientes de sus responsables.
  Las rutinas son SECURITY INVOKER, no elevan privilegios.
- S9 se entrega como consulta directa; la vista requerida se coordina con Valentina.
- U6 queda pendiente: este aporte no agrega columnas ni cambia constraints.
- El informe PDF de Etapa 2 describe porcentajes 5/10 anteriores. Actualizar ese
  informe al integrar: con 10.000 los netos correctos son 9.000, 8.000 y 7.000.

## Qué cubren las pruebas

`database/tests/santiago_tests.sql` prueba tasas, redondeo, IDs ausentes,
antigüedad, creación de stock, rechazo de estados y vacíos, reprocesamiento,
bodega incompatible, falta de stock, atomicidad del CALL con fallo en el segundo
vino y total histórico. El runner `tools/validacion_sql/validar.mjs` comprueba además
la ausencia de multiplicación de stock en S9 y los resultados de S10–S12/U1–U5.
No reemplaza el `db_tests.sql` de Renata ni certifica todas las RN. Al integrar
triggers de venta, ajustar los fixtures a sus efectos y agregar casos de regresión.
