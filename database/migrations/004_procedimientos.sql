-- Santiago · RN-10/RN-11. CALL participa en la transacción del invocador.
-- Sin COMMIT interno ni excepciones silenciadas: cualquier error revierte el CALL.
-- Protección transitoria ante RN-12 aún ausente: SHARE bloquea escrituras de
-- renglones durante el procesamiento. Es global por tabla (ver docs/contratos_datos.md).
CREATE OR REPLACE PROCEDURE sp_procesar_ingreso(p_codigo INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_ingreso ingreso%ROWTYPE; r RECORD;
BEGIN
    LOCK TABLE renglon_ingreso IN SHARE MODE;
    SELECT * INTO v_ingreso FROM ingreso WHERE codigo_ingreso = p_codigo FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ingreso % inexistente', p_codigo USING ERRCODE = 'P0002';
    END IF;
    IF v_ingreso.estado <> 'terminado' THEN
        RAISE EXCEPTION 'RN-10: ingreso % debe estar terminado', p_codigo USING ERRCODE = '23514';
    END IF;
    IF NOT EXISTS (SELECT FROM renglon_ingreso WHERE codigo_ingreso = p_codigo) THEN
        RAISE EXCEPTION 'Ingreso sin renglones' USING ERRCODE = '23514';
    END IF;
    FOR r IN SELECT ri.*, v.cuit_bodega FROM renglon_ingreso ri
             JOIN vino v USING (cod_vino) WHERE codigo_ingreso = p_codigo ORDER BY cod_vino
    LOOP
        IF r.cantidad <= 0 OR r.cuit_bodega <> v_ingreso.cuit_bodega THEN
            RAISE EXCEPTION 'Cantidad inválida o bodega incompatible para vino %', r.cod_vino USING ERRCODE = '23514';
        END IF;
        INSERT INTO stock_deposito(cod_vino, cantidad) VALUES (r.cod_vino, r.cantidad)
        ON CONFLICT(cod_vino) DO UPDATE
          SET cantidad = stock_deposito.cantidad + EXCLUDED.cantidad;
    END LOOP;
    UPDATE ingreso SET estado = 'procesado' WHERE codigo_ingreso = p_codigo;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_procesar_transferencia(p_numero INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_transferencia transferencia%ROWTYPE; r RECORD; v_stock INTEGER;
BEGIN
    LOCK TABLE renglon_transferencia IN SHARE MODE;
    SELECT * INTO v_transferencia FROM transferencia
    WHERE numero_solicitud = p_numero FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transferencia % inexistente', p_numero USING ERRCODE = 'P0002';
    END IF;
    IF v_transferencia.estado <> 'terminado' THEN
        RAISE EXCEPTION 'RN-11: transferencia % debe estar terminada', p_numero USING ERRCODE = '23514';
    END IF;
    IF NOT EXISTS (SELECT FROM renglon_transferencia WHERE numero_solicitud = p_numero) THEN
        RAISE EXCEPTION 'Transferencia sin renglones' USING ERRCODE = '23514';
    END IF;
    -- Orden común de vinos reduce deadlocks entre documentos con varios renglones.
    FOR r IN SELECT * FROM renglon_transferencia
             WHERE numero_solicitud = p_numero ORDER BY cod_vino
    LOOP
        IF r.cantidad <= 0 THEN
            RAISE EXCEPTION 'Cantidad inválida para vino %', r.cod_vino USING ERRCODE = '23514';
        END IF;
        SELECT cantidad INTO v_stock FROM stock_deposito
        WHERE cod_vino = r.cod_vino FOR UPDATE;
        IF NOT FOUND OR v_stock < r.cantidad THEN
            RAISE EXCEPTION 'RN-11: stock de depósito ausente o insuficiente para vino %', r.cod_vino
              USING ERRCODE = '23514';
        END IF;
        UPDATE stock_deposito SET cantidad = cantidad - r.cantidad WHERE cod_vino = r.cod_vino;
        INSERT INTO stock_sala(id_sala, cod_vino, cantidad)
        VALUES (v_transferencia.id_sala, r.cod_vino, r.cantidad)
        ON CONFLICT(id_sala, cod_vino) DO UPDATE
          SET cantidad = stock_sala.cantidad + EXCLUDED.cantidad;
    END LOOP;
    UPDATE transferencia SET estado = 'procesado' WHERE numero_solicitud = p_numero;
END;
$$;
