-- ============================================================
-- Archivo: 007_roles.sql
-- Etapa 2: Creación de Roles y Asignación de Privilegios Mínimos
-- ============================================================

-- 1) CREACIÓN DE ROLES BASE EN POSTGRESQL

-- Creamos los roles (si es que no existen previamente para evitar errores)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_admin_sistema') THEN
        CREATE ROLE rol_admin_sistema LOGIN PASSWORD 'Admin123*';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_operador_ventas') THEN
        CREATE ROLE rol_operador_ventas LOGIN PASSWORD 'Ventas123*';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_gerente_comercial') THEN
        CREATE ROLE rol_gerente_comercial LOGIN PASSWORD 'Gerente123*';
    END IF;
END
$$;

-- -------------------------------------------------------------

-- 2) ASIGNACIÓN DE PRIVILEGIOS: ROL ADMIN SISTEMA

-- El administrador tiene control total sobre todas las tablas del esquema

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin_sistema;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin_sistema;


-- -------------------------------------------------------------

-- 3) ASIGNACIÓN DE PRIVILEGIOS: ROL OPERADOR VENTAS

-- Puede consultar catálogos (vinos, salas, clientes) y registrar ventas (comprobantes y renglones)

GRANT SELECT ON vino, sala_venta, cliente, stock_sala TO rol_operador_ventas;
GRANT SELECT, INSERT, UPDATE ON comprobante, renglon_comprobante TO rol_operador_ventas;

-- Permiso para usar las secuencias de comprobantes al insertar nuevas ventas

GRANT USAGE, SELECT ON SEQUENCE comprobante_numero_comprobante_seq TO rol_operador_ventas;


-- -------------------------------------------------------------

-- 4) ASIGNACIÓN DE PRIVILEGIOS: ROL GERENTE COMERCIAL

-- El gerente tiene acceso de lectura (SELECT) a las tablas clave y a las vistas del sistema

GRANT SELECT ON vino, cliente, cliente_exportador, permiso_exportacion, comprobante TO rol_gerente_comercial;
GRANT SELECT ON vw_stock_total_vinos, vw_clientes_exportadores_info, vw_resumen_comprobantes TO rol_gerente_comercial;