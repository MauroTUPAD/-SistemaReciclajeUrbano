-- ==================================
-- SESIÓN 2 (Paso 2)
-- ==================================

PRINT 'SESIÓN 2 (Paso 2): Iniciar transacción y bloquear Cuenta 2';
BEGIN TRAN;
UPDATE dbo.CuentasBancarias
SET saldo = saldo + 100
WHERE id = 2;
PRINT '✓ Sesión 2 bloqueó la Cuenta 2. Saldo actualizado:';
SELECT saldo FROM dbo.CuentasBancarias WHERE id = 2;

-- ==================================
-- SESIÓN 2 (Paso 4 - El Deadlock)
-- ==================================

PRINT 'SESIÓN 2 (Paso 4): Intentar bloquear Cuenta 1 (DEADLOCK)';
PRINT '...ejecutando (esto provocará un deadlock)...';
UPDATE dbo.CuentasBancarias
SET saldo = saldo + 50
WHERE id = 1;

-- ¡DEADLOCK! SQL Server detectará el interbloqueo.
-- Una sesión (probablemente esta) fallará con el error 1205.
-- La otra sesión (Sesión 1) completará su UPDATE.

-- En la sesión que falló (la víctima), ejecuta (puede dar error si ya se cerró):
ROLLBACK TRAN;
PRINT '✓ Transacción de la sesión víctima revertida.';

-- SESIÓN 2 (Paso A2)

PRINT 'SESIÓN 2 (Paso A2): Actualizar y comitear el saldo';
UPDATE dbo.CuentasBancarias
SET saldo = 1100
WHERE id = 1;
COMMIT;
PRINT '✓ Sesión 2 actualizó y comiteó el saldo a 1100.';

-- SESIÓN 2 (Paso B2)

PRINT 'SESIÓN 2 (Paso B2): Intentar actualizar el saldo';
PRINT '...ejecutando (esto quedará en espera)...';
UPDATE dbo.CuentasBancarias
SET saldo = 1200
WHERE id = 1;
-- Esta sesión quedará BLOQUEADA hasta que la Sesión 1 termine.


-- SESIÓN 2 (Paso B4)

-- La consulta del Paso B2 ahora se completará.
PRINT '✓ Sesión 2 completó su UPDATE.';
COMMIT;
