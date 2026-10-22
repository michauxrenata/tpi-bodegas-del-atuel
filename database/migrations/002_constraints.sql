-- ======================================================================
-- ARCHIVO: 002_constraints.sql
-- ETAPA 2: Restricciones de Dominio, Integridad y Valores DEFAULT
-- ======================================================================

-- 1. VALORES POR DEFECTO (DEFAULT)

-- 1) El volumen de la botella de vino toma por defecto 750 ml (estándar vitivinícola)
ALTER TABLE vino 
ALTER COLUMN volumen_ml SET DEFAULT 750;

-- 2) El tipo de vino por defecto es 'tinto' (producto principal de la región)
ALTER TABLE vino 
ALTER COLUMN tipo SET DEFAULT 'tinto';

-- 3) El tipo de cliente por defecto al registrarse es 'socio' (club de vinos)
ALTER TABLE cliente 
ALTER COLUMN tipo_cliente SET DEFAULT 'socio';


-- ==========================================================================================


-- 2. RESTRICCIONES CHECK (Límites y Reglas de Negocio)
-- 1) La fecha de vencimiento debe ser posterior a la fecha de emisión
ALTER TABLE permiso_exportacion 
ADD CONSTRAINT chk_fechas_permiso 
CHECK (fecha_vencimiento > fecha_emision);

-- 2) Los precios de los vinos deben ser positivos
ALTER TABLE vino 
ADD CONSTRAINT chk_vino_precio_positivo 
CHECK (precio > 0);

-- 3) El volumen del vino debe ser mayor a cero
ALTER TABLE vino 
ADD CONSTRAINT chk_vino_volumen_positivo 
CHECK (volumen_ml > 0);

-- 4) La graduación alcohólica debe estar entre 0% y 100%
ALTER TABLE vino 
ADD CONSTRAINT chk_vino_graduacion 
CHECK (graduacion >= 0 AND graduacion <= 100);

-- 5) El porcentaje de cepa en la composición debe estar entre 0.01% y 100%
ALTER TABLE composicion_vino 
ADD CONSTRAINT chk_composicion_porcentaje 
CHECK (porcentaje > 0 AND porcentaje <= 100);

-- 6) Las cantidades ingresadas en depósito deben ser estrictamente positivas
ALTER TABLE renglon_ingreso 
ADD CONSTRAINT chk_cant_ingreso_positiva 
CHECK (cantidad > 0);

-- 7) Las cantidades de venta en comprobantes deben ser mayores a cero
ALTER TABLE renglon_comprobante 
ADD CONSTRAINT chk_cant_comprobante_positiva 
CHECK (cantidad > 0);

-- 8) El stock acumulado en sala no puede ser negativo
ALTER TABLE stock_sala 
ADD CONSTRAINT chk_stock_sala_no_negativo 
CHECK (cantidad >= 0);


-- ==========================================================================================


-- 3. UNICIDAD Y FORMATOS (UNIQUE / NOT NULL)
-- 1) El email del transportista debe ser único
ALTER TABLE transportista 
ADD CONSTRAINT uq_transportista_email 
UNIQUE (email);

-- 2)La razón social de la bodega debe ser única
ALTER TABLE bodega 
ADD CONSTRAINT uq_bodega_razon_social 
UNIQUE (razon_social);

-- 3) El nombre de la finca debe ser único
ALTER TABLE finca 
ADD CONSTRAINT uq_finca_nombre 
UNIQUE (nombre);

-- 4) El país de destino principal del cliente exportador no se repite si se requiere restringir por cuenta
ALTER TABLE cliente_exportador 
ADD CONSTRAINT uq_cliente_exportador_pais 
UNIQUE (pais_destino_principal);