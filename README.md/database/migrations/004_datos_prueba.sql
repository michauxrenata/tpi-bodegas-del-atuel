-- ============================================================================
-- BODEGAS DEL ATUEL - DATOS DE PRUEBA Y PRUEBA DE FUNCIONES
-- ============================================================================

-- 1. Insertar un cliente distribuidor de prueba
INSERT INTO cliente (
    nombre_razon_social, 
    tipo_doc, 
    nro_doc, 
    direccion, 
    localidad, 
    tipo_cliente
) VALUES (
    'Distribuidora El Atuel', 
    'CUIT', 
    '30-71123456-8', 
    'Av. Mitre 123', 
    'San Rafael', 
    'distribuidor'
)
ON CONFLICT (nro_doc) DO NOTHING;

-- 2. Insertar un cliente socio de prueba
INSERT INTO cliente (
    nombre_razon_social, 
    tipo_doc, 
    nro_doc, 
    direccion, 
    localidad, 
    tipo_cliente
) VALUES (
    'Juan Carlos Gómez', 
    'DNI', 
    '32987654', 
    'Calle Las Heras 456', 
    'San Rafael', 
    'socio'
)
ON CONFLICT (nro_doc) DO NOTHING;

-- 3. Probar la función de descuento para un monto de $10.000
SELECT 
    id_cliente, 
    nombre_razon_social, 
    tipo_cliente, 
    fn_calcular_descuento_cliente(id_cliente, 10000.00) AS total_con_descuento
FROM cliente;