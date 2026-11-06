-- ============================================================================
-- BODEGAS DEL ATUEL - SUITE DE PRUEBAS SQL (ETAPA 2)
-- Autor: Renata (QA / Pruebas)
-- ============================================================================

\echo '=== PRUEBA 1: Verificación de cálculo de descuentos ==='
SELECT id_cliente, nombre_razon_social, tipo_cliente, 
       fn_calcular_descuento_cliente(id_cliente, 10000.00) AS total_con_descuento
FROM cliente;

\echo '=== PRUEBA 2: Validación de Trigger - Cantidad válida en renglón (Éxito) ==='
-- 1. Insertar localidad completa
INSERT INTO localidad (codigo_postal, nombre, provincia, encargado_regional)
VALUES ('5600', 'San Rafael', 'Mendoza', 'Carlos Gomez')
ON CONFLICT (codigo_postal) DO NOTHING;

-- 2. Insertar bodega completa incluyendo domicilio obligatorio
INSERT INTO bodega (cuit, razon_social, domicilio)
VALUES ('30711234568', 'Bodegas del Atuel S.A.', 'Av. Balloffet 456')
ON CONFLICT (cuit) DO NOTHING;

-- 3. Insertar sala de ventas vinculada a la localidad
INSERT INTO sala_venta (calle, numero, dia_cierre, codigo_postal)
VALUES ('Av. San Martín', 123, 'Domingo', (SELECT codigo_postal FROM localidad LIMIT 1))
ON CONFLICT DO NOTHING;

-- 4. Insertar comprobante asociándolo a la sala existente
INSERT INTO comprobante (id_cliente, id_sala, fecha, total)
VALUES (1, (SELECT id_sala FROM sala_venta LIMIT 1), CURRENT_DATE, 6000.00);

-- 5. Insertar vino asociándolo a la bodega creada o existente
INSERT INTO vino (nombre, tipo, anada, volumen_ml, graduacion, precio, cuit_bodega)
VALUES (
    'Malbec Reserva', 
    'tinto', 
    2022, 
    750, 
    14.5, 
    1200.00, 
    (SELECT cuit FROM bodega LIMIT 1)
)
ON CONFLICT DO NOTHING;

-- 6. Insertar renglón asociándolo al comprobante y vino válidos
INSERT INTO renglon_comprobante (numero_comprobante, cod_vino, cantidad, precio_unitario, descuento, subtotal)
VALUES (
    currval(pg_get_serial_sequence('comprobante', 'numero_comprobante')), 
    (SELECT cod_vino FROM vino LIMIT 1), 
    5, 1200.00, 0, 6000.00
);

\echo '=== PRUEBA 3: Validación de Trigger - Cantidad inválida (Fallo esperado) ==='
DO $$
BEGIN
    INSERT INTO renglon_comprobante (numero_comprobante, cod_vino, cantidad, precio_unitario, descuento, subtotal)
    VALUES (
        currval(pg_get_serial_sequence('comprobante', 'numero_comprobante')), 
        (SELECT cod_vino FROM vino LIMIT 1), 
        0, 1200.00, 0, 0
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Prueba exitosa: Se capturó el error esperado del trigger -> %', SQLERRM;
END;
$$;