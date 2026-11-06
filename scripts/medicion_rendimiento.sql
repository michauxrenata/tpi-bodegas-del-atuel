-- ============================================================================
-- BODEGAS DEL ATUEL - MEDICIÓN DE RENDIMIENTO (ANTES VS. DESPUÉS)
-- Autor: Renata
-- ============================================================================

\echo '=== 1. MEDICIÓN ANTES: Consulta sin índice (Búsqueda por precio) ==='
-- Desactivamos temporalmente el uso de índices para simular la consulta "Antes"
SET enable_seqscan = ON;
SET enable_indexscan = OFF;

EXPLAIN ANALYZE
SELECT cod_vino, nombre, precio, graduacion
FROM vino
WHERE precio > 1000.00;

\echo '=== 2. CREACIÓN DEL ÍNDICE ==='
CREATE INDEX IF NOT EXISTS idx_vino_precio ON vino(precio);

\echo '=== 3. MEDICIÓN DESPUÉS: Consulta optimizada con índice ==='
-- Reactivamos el uso de índices para medir el "Después"
SET enable_indexscan = ON;

EXPLAIN ANALYZE
SELECT cod_vino, nombre, precio, graduacion
FROM vino
WHERE precio > 1000.00;