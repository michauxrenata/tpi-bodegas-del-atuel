-- ============================================================
-- Archivo: 007_roles.sql
-- Etapa 2: Creación de Roles y Asignación de Privilegios Mínimos
-- ============================================================

-- Ejecutar después de:
-- 001_esquema.sql
-- 003_funciones.sql
-- 004_procedimientos.sql
-- 005_triggers.sql
-- 006_vistas.sql


-- ============================================================
-- 1. CREACIÓN DE ROLES SIN CONTRASEÑAS
-- ============================================================

-- Los roles representan conjuntos de permisos.
-- Los usuarios de conexión se crean por separado.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'rol_admin_sistema'
    ) THEN
        CREATE ROLE rol_admin_sistema NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'rol_operador_ventas'
    ) THEN
        CREATE ROLE rol_operador_ventas NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'rol_gerente_comercial'
    ) THEN
        CREATE ROLE rol_gerente_comercial NOLOGIN;
    END IF;
END
$$;

-- Asegurar que los roles existentes tampoco
-- puedan iniciar sesión directamente.
ALTER ROLE rol_admin_sistema NOLOGIN;
ALTER ROLE rol_operador_ventas NOLOGIN;
ALTER ROLE rol_gerente_comercial NOLOGIN;


-- ============================================================
-- 2. SEGURIDAD GENERAL DEL ESQUEMA
-- ============================================================

-- Retirar permisos públicos.
REVOKE ALL ON SCHEMA public FROM PUBLIC;

REVOKE ALL ON ALL TABLES IN SCHEMA public
FROM PUBLIC;

REVOKE ALL ON ALL SEQUENCES IN SCHEMA public
FROM PUBLIC;

REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public
FROM PUBLIC;

-- Retirar privilegios anteriores del operador
-- y gerente para reasignar únicamente los necesarios.
REVOKE ALL ON ALL TABLES IN SCHEMA public
FROM rol_operador_ventas, rol_gerente_comercial;

REVOKE ALL ON ALL SEQUENCES IN SCHEMA public
FROM rol_operador_ventas, rol_gerente_comercial;

REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public
FROM rol_operador_ventas, rol_gerente_comercial;

-- Acceso controlado al esquema.
GRANT USAGE ON SCHEMA public
TO rol_admin_sistema,
   rol_operador_ventas,
   rol_gerente_comercial;


-- ============================================================
-- 3. ROL ADMINISTRADOR DEL SISTEMA
-- ============================================================

-- Administración de objetos existentes.
-- La propiedad real se configura por separado.

GRANT CREATE ON SCHEMA public
TO rol_admin_sistema;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
TO rol_admin_sistema;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public
TO rol_admin_sistema;

GRANT EXECUTE ON ALL ROUTINES IN SCHEMA public
TO rol_admin_sistema;


-- ============================================================
-- 4. ROL OPERADOR DE VENTAS / API
-- ============================================================

-- Consultar información necesaria para las operaciones.
GRANT SELECT ON
    vino,
    composicion_vino,
    cepa,
    maridaje,
    vino_maridaje,
    bodega,
    sala_venta,
    localidad,
    cliente,
    cliente_socio,
    cliente_distribuidor,
    cliente_exportador,
    permiso_exportacion,
    transportista,
    stock_deposito,
    stock_sala,
    comprobante,
    renglon_comprobante,
    ingreso,
    renglon_ingreso,
    transferencia,
    renglon_transferencia
TO rol_operador_ventas;


-- Registrar y actualizar comprobantes de venta.
GRANT INSERT, UPDATE ON
    comprobante,
    renglon_comprobante
TO rol_operador_ventas;


-- Registrar ingresos y transferencias.
GRANT INSERT, UPDATE ON
    ingreso,
    renglon_ingreso,
    transferencia,
    renglon_transferencia
TO rol_operador_ventas;


-- Las escrituras en stock NO se conceden directamente.
-- Requieren procedimientos seguros coordinados
-- con Santiago y triggers de Sol.


-- Uso de secuencias para insertar nuevos registros.
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public
TO rol_operador_ventas;


-- ============================================================
-- 5. EJECUCIÓN DE FUNCIONES DE SANTIAGO
-- ============================================================

GRANT EXECUTE ON FUNCTION
    fn_descuento_cliente(INTEGER)
TO rol_operador_ventas;

GRANT EXECUTE ON FUNCTION
    fn_calcular_descuento_cliente(INTEGER, NUMERIC)
TO rol_operador_ventas;

GRANT EXECUTE ON FUNCTION
    fn_stock_sala(INTEGER, INTEGER)
TO rol_operador_ventas;

GRANT EXECUTE ON FUNCTION
    fn_total_comprobante(INTEGER)
TO rol_operador_ventas;

GRANT EXECUTE ON FUNCTION
    fn_antiguedad_anios(DATE)
TO rol_operador_ventas;

GRANT EXECUTE ON FUNCTION
    fn_antiguedad_anios(DATE, DATE)
TO rol_operador_ventas;


-- ============================================================
-- 6. EJECUCIÓN DE PROCEDIMIENTOS TRANSACCIONALES
-- ============================================================

GRANT EXECUTE ON PROCEDURE
    sp_procesar_ingreso(INTEGER)
TO rol_operador_ventas;

GRANT EXECUTE ON PROCEDURE
    sp_procesar_transferencia(INTEGER)
TO rol_operador_ventas;


-- ============================================================
-- 7. ACCESO A LAS VISTAS DEL SISTEMA
-- ============================================================

-- El operador consulta las vistas desde la API.
GRANT SELECT ON
    vw_stock_total_vinos,
    vw_clientes_exportadores_info,
    vw_resumen_comprobantes
TO rol_operador_ventas;


-- ============================================================
-- 8. ROL GERENTE COMERCIAL - SOLO LECTURA
-- ============================================================

-- Acceso a reportes mediante vistas.
GRANT SELECT ON
    vw_stock_total_vinos,
    vw_clientes_exportadores_info,
    vw_resumen_comprobantes
TO rol_gerente_comercial;


-- ============================================================
-- FIN DEL ARCHIVO 007_roles.sql
-- ============================================================
