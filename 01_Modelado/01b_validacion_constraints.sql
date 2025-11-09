/******************************************************************************
 TFI - Bases de Datos I
 Script: 01b_validacion_constraints.sql (T-SQL / SQL Server)
 
 ETAPA 1: VALIDACIÓN PRÁCTICA DE CONSTRAINTS
 
 Sistema: Gestión de Reciclaje Urbano
 Autor: Mauro Ezequiel Ponce
 Fecha: Noviembre 2025
 
 Descripción:
 Este script demuestra que las restricciones de integridad (PK, FK, UNIQUE, CHECK)
 funcionan correctamente mediante pruebas de inserción válidas e inválidas.

******************************************************************************/


USE [SistemaReciclajeUrbano];
GO
SET NOCOUNT ON;
GO

PRINT '';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '  VALIDACIÓN DE CONSTRAINTS - ETAPA 1';
PRINT '  Sistema de Gestión de Reciclaje Urbano';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';
PRINT 'Este script ejecuta 6 pruebas:';
PRINT '  → 2 inserciones VÁLIDAS (deben funcionar)';
PRINT '  → 4 inserciones INVÁLIDAS (deben FALLAR con errores reales)';
PRINT '';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';

------------------------------------------------------------
-- PARTE A: INSERCIONES VÁLIDAS
------------------------------------------------------------
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'PARTE A: INSERCIONES VÁLIDAS';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';

------------------------------------------------------------
-- PRUEBA 1: Inserción válida en CategoriasMaterial
------------------------------------------------------------
PRINT '┌─────────────────────────────────────────────────────────────┐';
PRINT '│ PRUEBA 1: Inserción VÁLIDA en CategoriasMaterial           │';
PRINT '└─────────────────────────────────────────────────────────────┘';
PRINT 'Acción: Insertar nueva categoría "Tetra Pak"';
PRINT '';

BEGIN TRY
    INSERT INTO dbo.CategoriasMaterial (nombre, descripcion)
    VALUES (N'Tetra Pak', N'Envases de cartón plastificado');

    DECLARE @id_cat INT = SCOPE_IDENTITY();
    PRINT '✓ ÉXITO: Categoría insertada correctamente (id=' + CAST(@id_cat AS NVARCHAR(10)) + ')';
END TRY
BEGIN CATCH
    PRINT '✗ ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';
GO


------------------------------------------------------------
-- PRUEBA 2: Inserción válida en RegistrosDeposito
------------------------------------------------------------
PRINT '┌─────────────────────────────────────────────────────────────┐';
PRINT '│ PRUEBA 2: Inserción VÁLIDA en RegistrosDeposito            │';
PRINT '└─────────────────────────────────────────────────────────────┘';
PRINT 'Acción: Registrar depósito de 30.5 kg de Plástico PET en EcoPunto Centro';
PRINT '';

BEGIN TRY
    INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg, fecha_deposito)
    VALUES (1, 1, 30.50, '2024-11-05 14:30:00');

    DECLARE @id_dep INT = SCOPE_IDENTITY();
    PRINT '✓ ÉXITO: Registro de depósito insertado correctamente (id=' + CAST(@id_dep AS NVARCHAR(10)) + ')';
END TRY
BEGIN CATCH
    PRINT '✗ ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';
GO


------------------------------------------------------------
-- PARTE B: INSERCIONES INVÁLIDAS (VIOLACIONES DE CONSTRAINTS)
------------------------------------------------------------
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'PARTE B: INSERCIONES INVÁLIDAS (Violación de Constraints)';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';

------------------------------------------------------------
-- PRUEBA 3: Violación de UNIQUE (CategoriasMaterial.nombre)
------------------------------------------------------------
PRINT '┌─────────────────────────────────────────────────────────────┐';
PRINT '│ PRUEBA 3: Violación de UNIQUE (nombre duplicado)           │';
PRINT '└─────────────────────────────────────────────────────────────┘';
PRINT 'Acción: Intentar insertar categoría con nombre "Plástico PET" (ya existe)';
PRINT 'Resultado esperado: Error 2627 - Violación de UQ_CategoriasMaterial_Nombre';
PRINT '';
-- ❌ Esta debe FALLAR realmente
INSERT INTO dbo.CategoriasMaterial (nombre, descripcion)
VALUES (N'Plástico PET', N'Duplicado para probar constraint UNIQUE');
PRINT '';
GO


------------------------------------------------------------
-- PRUEBA 4: Violación de CHECK (cantidad negativa)
------------------------------------------------------------
PRINT '┌─────────────────────────────────────────────────────────────┐';
PRINT '│ PRUEBA 4: Violación de CHECK (cantidad negativa)           │';
PRINT '└─────────────────────────────────────────────────────────────┘';
PRINT 'Acción: Intentar registrar depósito con cantidad = -10.00 kg';
PRINT 'Resultado esperado: Error 547 - Violación de CHK_Registro_CantidadPositiva';
PRINT '';
-- ❌ Esta debe FALLAR realmente
INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg)
VALUES (1, 1, -10.00);
PRINT '';
GO


------------------------------------------------------------
-- PRUEBA 5: Violación de FOREIGN KEY (id_centro_fk inexistente)
------------------------------------------------------------
PRINT '┌─────────────────────────────────────────────────────────────┐';
PRINT '│ PRUEBA 5: Violación de FOREIGN KEY (centro inexistente)    │';
PRINT '└─────────────────────────────────────────────────────────────┘';
PRINT 'Acción: Intentar registrar depósito en centro con id=999 (no existe)';
PRINT 'Resultado esperado: Error 547 - Violación de FK_Registro_Centro';
PRINT '';
-- ❌ Esta debe FALLAR realmente
INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg)
VALUES (999, 1, 20.00);
PRINT '';
GO


------------------------------------------------------------
-- PRUEBA 6: Violación de UNIQUE (nombre duplicado en CentrosAcopio)
------------------------------------------------------------
PRINT '┌─────────────────────────────────────────────────────────────┐';
PRINT '│ PRUEBA 6: Violación de UNIQUE (centro duplicado)           │';
PRINT '└─────────────────────────────────────────────────────────────┘';
PRINT 'Acción: Intentar insertar centro con nombre "EcoPunto Centro" (ya existe)';
PRINT 'Resultado esperado: Error 2627 - Violación de UQ_CentrosAcopio_Nombre';
PRINT '';
-- ❌ Esta debe FALLAR realmente
INSERT INTO dbo.CentrosAcopio (nombre, direccion, horario)
VALUES (N'EcoPunto Centro', N'Calle Falsa 123', N'24hs');
PRINT '';
GO


------------------------------------------------------------
-- RESUMEN FINAL
------------------------------------------------------------
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'RESUMEN FINAL DE VALIDACIÓN';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'RESULTADOS ESPERADOS:';
PRINT '  ✓ PRUEBA 1  → Inserción válida';
PRINT '  ✓ PRUEBA 2  → Inserción válida';
PRINT '  ✗ PRUEBA 3  → Error 2627 (UNIQUE)';
PRINT '  ✗ PRUEBA 4  → Error 547 (CHECK)';
PRINT '  ✗ PRUEBA 5  → Error 547 (FOREIGN KEY)';
PRINT '  ✗ PRUEBA 6  → Error 2627 (UNIQUE)';
PRINT '';
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'Todas las constraints responden correctamente a datos inválidos.';
PRINT 'Guarda las capturas del panel de mensajes mostrando los errores.';
PRINT '════════════════════════════════════════════════════════════════';
GO

/******************************************************************************
 FIN DEL SCRIPT: 01b_validacion_constraints.sql

 PARA EL INFORME:
 - Capturar el panel de mensajes (con los errores 2627, 547, etc.)
 - Incluirlos en la sección de validación de constraints del TFI.
******************************************************************************/
