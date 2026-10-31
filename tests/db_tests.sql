-- ============================================================================
-- BODEGAS DEL ATUEL - SUITE DE PRUEBAS SQL (ETAPA 2)
-- Autor: Renata (QA / Pruebas)
-- ============================================================================

\echo '=== PRUEBA 1: Verificacion de calculo de descuentos ==='
SELECT id_cliente, nombre_razon_social, tipo_cliente, 
       fn_calcular_descuento_cliente(id_cliente, 10000.00) AS total_con_descuento
FROM cliente;

\echo '=== PRUEBA 2: Validacion de Trigger - Cantidad valida en renglon (Exito) ==='
INSERT INTO renglon_comprobante (id_comprobante, nro_renglon, id_vino, cantidad, precio_unitario)
VALUES (1, 1, 1, 5, 1200.00)
ON CONFLICT DO NOTHING;

\echo '=== PRUEBA 3: Validacion de Trigger - Cantidad invalida (Fallo esperado) ==='
DO $
BEGIN
    INSERT INTO renglon_comprobante (id_comprobante, nro_renglon, id_vino, cantidad, precio_unitario)
    VALUES (1, 2, 1, 0, 1200.00);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Prueba exitosa: Se capturo el error esperado -> %', SQLERRM;
END;
$;
