-- ============================================================================
-- ETAPA 5: CONCURRENCIA Y TRANSACCIONES
-- Sistema de Gestión de Reciclaje Urbano
-- ============================================================================

PRINT '';
PRINT '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::';
PRINT 'ETAPA 5: CONCURRENCIA Y TRANSACCIONES';
PRINT '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::';
PRINT '';
USE SistemaReciclajeUrbano;
GO

-- ============================================================================
-- PARTE 1: TABLA DE PRUEBA
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 1: Creando tabla de prueba "CuentasBancarias"                |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

-- Creamos una tabla simple para simular transacciones
IF OBJECT_ID('dbo.CuentasBancarias', 'U') IS NOT NULL
    DROP TABLE dbo.CuentasBancarias;
GO

CREATE TABLE dbo.CuentasBancarias (
    id INT PRIMARY KEY,
    nombre_titular NVARCHAR(100),
    saldo DECIMAL(10, 2) NOT NULL CHECK (saldo >= 0)
);

-- Insertamos datos de prueba
INSERT INTO dbo.CuentasBancarias (id, nombre_titular, saldo)
VALUES
(1, 'Cuenta de Ahorro A', 1000.00),
(2, 'Cuenta de Ahorro B', 500.00);

PRINT '✓ Tabla "CuentasBancarias" creada y poblada.';
PRINT '';
SELECT * FROM dbo.CuentasBancarias;
PRINT '';


-- ============================================================================
-- PARTE 2: SIMULACIÓN DE DEADLOCK (Punto 1 de la consigna)
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 2: Simulación de Deadlock (Interbloqueo)                     |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';
PRINT 'Instrucciones:';
PRINT '1. Abre DOS ventanas de consulta (Query) en SSMS.';
PRINT '2. Llama a una "Sesión 1" y a la otra "Sesión 2".';
PRINT '3. Ejecuta los pasos en el orden exacto indicado.';
PRINT '----------------------------------------------------------------------';
PRINT '';

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
-- SESIÓN 1 (Paso 3)
-- ==================================

PRINT 'SESIÓN 1 (Paso 3): Intentar bloquear Cuenta 2 (en espera)';
PRINT '...ejecutando (esto quedará en espera)...';
UPDATE dbo.CuentasBancarias
SET saldo = saldo - 50
WHERE id = 2;
-- Esta sesión quedará bloqueada, esperando a que la Sesión 2 libere la Cuenta 2.


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

-- DOCUMENTACIÓN DEL ERROR (lo que debes capturar):
-- Msg 1205, Level 13, State 51, Line X
-- Transaction (Process ID X) was deadlocked on lock resources with another process
-- and has been chosen as the deadlock victim. Rerun the transaction.


-- ==================================
-- LIMPIEZA (Ejecutar al final)
-- ==================================

-- En la sesión que no falló, ejecuta:
ROLLBACK TRAN;
PRINT '✓ Transacción de la sesión ganadora revertida.';

-- En la sesión que falló (la víctima), ejecuta (puede dar error si ya se cerró):
ROLLBACK TRAN;
PRINT '✓ Transacción de la sesión víctima revertida.';

-- Restaurar saldos originales
UPDATE dbo.CuentasBancarias SET saldo = 1000 WHERE id = 1;
UPDATE dbo.CuentasBancarias SET saldo = 500 WHERE id = 2;
PRINT '✓ Saldos restaurados.';
SELECT * FROM dbo.CuentasBancarias;



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


-- SESIÓN 2 (Paso A2)

PRINT 'SESIÓN 2 (Paso A2): Actualizar y comitear el saldo';
UPDATE dbo.CuentasBancarias
SET saldo = 1100
WHERE id = 1;
COMMIT;
PRINT '✓ Sesión 2 actualizó y comiteó el saldo a 1100.';


-- SESIÓN 1 (Paso A3)

PRINT 'SESIÓN 1 (Paso A3): Segunda lectura DENTRO de la misma TX';
PRINT 'Lectura 2 (Después del UPDATE en Sesión 2):';
SELECT * FROM dbo.CuentasBancarias WHERE id = 1;
-- Saldo esperado: 1100.00

PRINT '¡OBSERVACIÓN! El saldo cambió DENTRO de la misma transacción.';
PRINT 'Esto es una LECTURA NO REPETIBLE (Non-Repeatable Read).';
COMMIT;


-- LIMPIEZA PRUEBA A

UPDATE dbo.CuentasBancarias SET saldo = 1000 WHERE id = 1;
PRINT '✓ Saldo de Prueba A restaurado.';


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


-- SESIÓN 2 (Paso B2)

PRINT 'SESIÓN 2 (Paso B2): Intentar actualizar el saldo';
PRINT '...ejecutando (esto quedará en espera)...';
UPDATE dbo.CuentasBancarias
SET saldo = 1200
WHERE id = 1;
-- Esta sesión quedará BLOQUEADA hasta que la Sesión 1 termine.


-- SESIÓN 1 (Paso B3)

PRINT 'SESIÓN 1 (Paso B3): Segunda lectura DENTRO de la misma TX';
PRINT 'Lectura 2 (Mientras Sesión 2 espera):';
SELECT * FROM dbo.CuentasBancarias WHERE id = 1;
-- Saldo esperado: 1000.00

PRINT '¡OBSERVACIÓN! El saldo NO cambió.';
PRINT 'REPEATABLE READ previene la lectura no repetible.';
COMMIT;
PRINT '✓ Sesión 1 comiteada. Esto libera el bloqueo.';


-- SESIÓN 2 (Paso B4)

-- La consulta del Paso B2 ahora se completará.
PRINT '✓ Sesión 2 completó su UPDATE.';
COMMIT;


-- LIMPIEZA PRUEBA B

UPDATE dbo.CuentasBancarias SET saldo = 1000 WHERE id = 1;
PRINT '✓ Saldo de Prueba B restaurado.';
SELECT * FROM dbo.CuentasBancarias;



-- ============================================================================
-- PARTE 4: PROCEDIMIENTO CON TRANSACCIÓN Y RETRY (Punto 2 de la consigna)
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 4: Procedimiento Almacenado con Transacción y Retry          |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

IF OBJECT_ID('dbo.sp_TransferenciaSegura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TransferenciaSegura;
GO

CREATE PROCEDURE dbo.sp_TransferenciaSegura
    @CuentaOrigenID INT,
    @CuentaDestinoID INT,
    @Monto DECIMAL(10, 2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Intentos INT = 0;
    DECLARE @MaxIntentos INT = 3;
    DECLARE @ErrorDeadlock INT = 1205;
    
    -- Bucle de reintento
    WHILE @Intentos < @MaxIntentos
    BEGIN
        SET @Intentos = @Intentos + 1;
        
        BEGIN TRY
            -- Iniciar transacción explícita
            BEGIN TRANSACTION;
            
            PRINT 'Intento ' + CAST(@Intentos AS VARCHAR) + ': Iniciando transferencia...';
            
            -- 1. Verificar fondos
            DECLARE @SaldoActualOrigen DECIMAL(10, 2);
            SELECT @SaldoActualOrigen = saldo 
            FROM dbo.CuentasBancarias 
            WHERE id = @CuentaOrigenID;
            
            IF @SaldoActualOrigen IS NULL OR @SaldoActualOrigen < @Monto
            BEGIN
                RAISERROR('Fondos insuficientes o cuenta origen no existe.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Simular un pequeño retraso para facilitar deadlocks
            WAITFOR DELAY '00:00:00.050';
            
            -- 2. Debitar de origen
            UPDATE dbo.CuentasBancarias
            SET saldo = saldo - @Monto
            WHERE id = @CuentaOrigenID;
            
            -- 3. Acreditar en destino
            UPDATE dbo.CuentasBancarias
            SET saldo = saldo + @Monto
            WHERE id = @CuentaDestinoID;
            
            -- 4. Confirmar transacción
            COMMIT TRANSACTION;
            
            PRINT '✓ Intento ' + CAST(@Intentos AS VARCHAR) + ': Transferencia exitosa.';
            BREAK; -- Salir del bucle si fue exitoso
            
        END TRY
        BEGIN CATCH
            -- Hubo un error, deshacer la transacción
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            DECLARE @ErrorNumero INT = ERROR_NUMBER();
            
            -- Verificar si es un Deadlock (Error 1205)
            IF @ErrorNumero = @ErrorDeadlock
            BEGIN
                PRINT '✗ Intento ' + CAST(@Intentos AS VARCHAR) + ': ¡Deadlock detectado! Reintentando...';
                WAITFOR DELAY '00:00:00.100'; -- Espera corta antes de reintentar
                -- Continuar al siguiente ciclo del WHILE
            END
            ELSE
            BEGIN
                -- Es un error diferente, no reintentar
                PRINT '✗ Error grave detectado. Abortando.';
                RAISERROR('Error en transferencia: %s', 16, 1, ERROR_MESSAGE());
                BREAK; -- Salir del bucle
            END
        END CATCH
    END; -- Fin del WHILE
    
    IF @Intentos = @MaxIntentos AND @ErrorNumero = @ErrorDeadlock
    BEGIN
        PRINT '✗ Transferencia fallida después de ' + CAST(@MaxIntentos AS VARCHAR) + ' intentos por deadlock.';
    END
END;
GO

PRINT '✓ Procedimiento "sp_TransferenciaSegura" creado.';
PRINT '';

-- Prueba del procedimiento (sin concurrencia)
PRINT 'Probando transferencia segura (uso normal):';
SELECT * FROM dbo.CuentasBancarias;
EXEC dbo.sp_TransferenciaSegura @CuentaOrigenID = 1, @CuentaDestinoID = 2, @Monto = 100.00;
SELECT * FROM dbo.CuentasBancarias;

-- Restaurar saldos finales
UPDATE dbo.CuentasBancarias SET saldo = 1000 WHERE id = 1;
UPDATE dbo.CuentasBancarias SET saldo = 500 WHERE id = 2;
PRINT '✓ Saldos restaurados.';
PRINT '';


-- ============================================================================
-- PARTE 5: INFORME DE OBSERVACIONES (Punto 4 de la consigna)
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 5: Informe Breve de Observaciones (Para tu entrega)          |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

PRINT '✓ ETAPA 5 COMPLETADA. Revisa las instrucciones de cada parte.';
PRINT '';
