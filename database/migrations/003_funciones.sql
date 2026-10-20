-- ============================================================================
-- BODEGAS DEL ATUEL - 003_FUNCIONES.SQL
-- ============================================================================

-- Función: Calcular descuento a clientes según su categoría
CREATE OR REPLACE FUNCTION fn_calcular_descuento_cliente(
    p_id_cliente INTEGER,
    p_monto NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
    v_tipo_cliente tipo_cliente_enum;
    v_descuento NUMERIC := 0;
BEGIN
    SELECT tipo_cliente INTO v_tipo_cliente 
    FROM cliente 
    WHERE id_cliente = p_id_cliente;

    IF v_tipo_cliente = 'distribuidor' THEN
        v_descuento := p_monto * 0.10;
    ELSIF v_tipo_cliente = 'socio' THEN
        v_descuento := p_monto * 0.05;
    END IF;

    RETURN p_monto - v_descuento;
END;
$$ LANGUAGE plpgsql;
