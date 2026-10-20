-- ============================================================================
-- BODEGAS DEL ATUEL - 005_TRIGGERS.SQL
-- ============================================================================

-- Función Trigger para auditar o validar cambios
CREATE OR REPLACE FUNCTION fn_trg_validar_renglon_comprobante()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad en el renglón del comprobante debe ser mayor a 0';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sobre la tabla renglon_comprobante
DROP TRIGGER IF EXISTS trg_validar_renglon ON renglon_comprobante;
CREATE TRIGGER trg_validar_renglon
BEFORE INSERT OR UPDATE ON renglon_comprobante
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validar_renglon_comprobante();
