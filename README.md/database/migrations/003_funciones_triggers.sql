-- ============================================================================
-- BODEGAS DEL ATUEL - TRABAJO PRÁCTICO INTEGRADOR
-- Script 003_funciones_triggers.sql - Etapa 2: Funciones y Triggers
-- ============================================================================

-- 1. FUNCIÓN Y TRIGGER: ACTUALIZAR STOCK AL VENDER
CREATE OR REPLACE FUNCTION fn_actualizar_stock_producto()
RETURNS TRIGGER AS $$
BEGIN
    -- Descontar la cantidad vendida del stock actual del producto
    UPDATE producto
    SET stock_actual = stock_actual - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_actualizar_stock
AFTER INSERT ON detalle_comprobante
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_stock_producto();


-- 2. FUNCIÓN: CALCULAR DESCUENTO SEGÚN TIPO DE CLIENTE

CREATE OR REPLACE FUNCTION fn_calcular_descuento_cliente(
    p_id_cliente INTEGER,
    p_monto NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
    v_tipo_cliente tipo_cliente_enum;
    v_descuento NUMERIC := 0;
BEGIN
    -- Corregido: tipo_cliente en lugar de tipo
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


-- 3. FUNCIÓN Y TRIGGER: VALIDAR COMPROBANTE CON DETALLES ANTES DE PROCESAR
CREATE OR REPLACE FUNCTION fn_validar_comprobante_procesado()
RETURNS TRIGGER AS $$
DECLARE
    v_cant_items INT;
BEGIN
    IF NEW.estado IN ('terminado', 'procesado') THEN
        SELECT COUNT(*) INTO v_cant_items 
        FROM detalle_comprobante 
        WHERE id_comprobante = NEW.id_comprobante;
        
        IF v_cant_items = 0 THEN
            RAISE EXCEPTION 'No se puede procesar un comprobante sin ítems asociados.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_comprobante_procesado
BEFORE UPDATE ON comprobante
FOR EACH ROW
EXECUTE FUNCTION fn_validar_comprobante_procesado();