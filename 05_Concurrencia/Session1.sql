-- ==================================
-- SESIÓN 1 (Paso 1)
-- ==================================

PRINT 'SESIÓN 1 (Paso 1): Iniciar transacción y bloquear Cuenta 1';
BEGIN TRAN;
UPDATE dbo.CuentasBancarias
SET saldo = saldo - 100
WHERE id = 1;
PRINT '✓ Sesión 1 bloqueó la Cuenta 1. Saldo actualizado:';
SELECT saldo FROM dbo.CuentasBancarias WHERE id = 1;

-- ==================================
-- SESIÓN 1 (Paso 3)
-- ==================================

PRINT 'SESIÓN 1 (Paso 3): Intentar bloquear Cuenta 2 (en espera)';
PRINT '...ejecutando (esto quedará en espera)...';
UPDATE dbo.CuentasBancarias
SET saldo = saldo - 50
WHERE id = 2;
-- Esta sesión quedará bloqueada, esperando a que la Sesión 2 libere la Cuenta 2.

-- ==================================
-- LIMPIEZA (Ejecutar al final)
-- ==================================

-- En la sesión que no falló, ejecuta:
ROLLBACK TRAN;
PRINT '✓ Transacción de la sesión ganadora revertida.';

-- ============================================================================
-- PARTE 3: COMPARACIÓN DE NIVELES DE AISLAMIENTO (Punto 3 de la consigna)
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 3: Comparación de Niveles de Aislamiento (LO QUE FALTABA)    |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';
PRINT 'Usaremos dos sesiones para demostrar la "Lectura No Repetible" (Non-Repeatable Read)';
PRINT '----------------------------------------------------------------------';
PRINT '';

-- ==================================
-- PRUEBA A: READ COMMITTED (Permite lecturas no repetibles)
-- ==================================
PRINT '===== PRUEBA A: READ COMMITTED =====';

-- SESIÓN 1 (Paso A1)

PRINT 'SESIÓN 1 (Paso A1): Establecer READ COMMITTED e iniciar TX';
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;
PRINT 'Lectura 1 (Antes del UPDATE en Sesión 2):';
SELECT * FROM dbo.CuentasBancarias WHERE id = 1;
-- Saldo esperado: 1000.00

-- SESIÓN 1 (Paso A3)

PRINT 'SESIÓN 1 (Paso A3): Segunda lectura DENTRO de la misma TX';
PRINT 'Lectura 2 (Después del UPDATE en Sesión 2):';
SELECT * FROM dbo.CuentasBancarias WHERE id = 1;
-- Saldo esperado: 1100.00

PRINT '¡OBSERVACIÓN! El saldo cambió DENTRO de la misma transacción.';
PRINT 'Esto es una LECTURA NO REPETIBLE (Non-Repeatable Read).';
COMMIT;

-- ==================================
-- PRUEBA B: REPEATABLE READ (Evita lecturas no repetibles)
-- ==================================
PRINT '===== PRUEBA B: REPEATABLE READ =====';

-- SESIÓN 1 (Paso B1)

PRINT 'SESIÓN 1 (Paso B1): Establecer REPEATABLE READ e iniciar TX';
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRAN;
PRINT 'Lectura 1 (Antes del UPDATE en Sesión 2):';
SELECT * FROM dbo.CuentasBancarias WHERE id = 1;
-- Saldo esperado: 1000.00

-- SESIÓN 1 (Paso B3)

PRINT 'SESIÓN 1 (Paso B3): Segunda lectura DENTRO de la misma TX';
PRINT 'Lectura 2 (Mientras Sesión 2 espera):';
SELECT * FROM dbo.CuentasBancarias WHERE id = 1;
-- Saldo esperado: 1000.00

PRINT '¡OBSERVACIÓN! El saldo NO cambió.';
PRINT 'REPEATABLE READ previene la lectura no repetible.';
COMMIT;
PRINT '✓ Sesión 1 comiteada. Esto libera el bloqueo.';
