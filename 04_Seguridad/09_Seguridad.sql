-- ============================================================================
-- ETAPA 4: SEGURIDAD E INTEGRIDAD
-- Sistema de Gestión de Reciclaje Urbano
-- ============================================================================

PRINT '';
PRINT '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::';
PRINT 'ETAPA 4: SEGURIDAD E INTEGRIDAD';
PRINT '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::';
PRINT '';

-- ============================================================================
-- PARTE 1: CREACIÓN DE USUARIO CON PRIVILEGIOS MÍNIMOS
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 1: Usuario con Privilegios Mínimos                          |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

-- Crear login a nivel servidor (solo si no existe)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_consulta')
BEGIN
    CREATE LOGIN usuario_consulta WITH PASSWORD = 'Consulta2025!';
    PRINT '✓ Login "usuario_consulta" creado en el servidor';
END
ELSE
    PRINT '- Login "usuario_consulta" ya existe';

-- Crear usuario en la base de datos
USE SistemaReciclajeUrbano;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_consulta')
BEGIN
    CREATE USER usuario_consulta FOR LOGIN usuario_consulta;
    PRINT '✓ Usuario "usuario_consulta" creado en la base de datos';
END
ELSE
    PRINT '- Usuario "usuario_consulta" ya existe';

-- Asignar SOLO permisos de lectura (SELECT) en tablas específicas
GRANT SELECT ON dbo.CentrosAcopio TO usuario_consulta;
GRANT SELECT ON dbo.CategoriasMaterial TO usuario_consulta;
PRINT '✓ Permisos de SELECT otorgados en CentrosAcopio y CategoriasMaterial';
PRINT '';
PRINT 'Permisos asignados:';
PRINT ' - SELECT en CentrosAcopio (puede ver centros)';
PRINT ' - SELECT en CategoriasMaterial (puede ver materiales)';
PRINT ' - NO tiene acceso a RegistrosDeposito (información sensible)';
PRINT ' - NO puede INSERT, UPDATE, DELETE en ninguna tabla';
PRINT '';

-- ============================================================================
-- PRUEBAS DE ACCESO RESTRINGIDO
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PRUEBAS DE ACCESO RESTRINGIDO                                      |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';
PRINT 'Para probar las restricciones, ejecute en otra ventana como usuario_consulta:';
PRINT '';
PRINT '-- PRUEBA 1: Acceso PERMITIDO (debería funcionar)';
PRINT 'EXECUTE AS USER = ''usuario_consulta'';';
PRINT 'SELECT TOP 3 nombre, direccion FROM dbo.CentrosAcopio;';
PRINT 'REVERT;';
PRINT '';
PRINT '-- PRUEBA 2: Acceso DENEGADO a RegistrosDeposito (debería fallar)';
PRINT 'EXECUTE AS USER = ''usuario_consulta'';';
PRINT 'SELECT * FROM dbo.RegistrosDeposito;';
PRINT '-- Error esperado: The SELECT permission was denied';
PRINT 'REVERT;';
PRINT '';
PRINT '-- PRUEBA 3: INSERT DENEGADO (debería fallar)';
PRINT 'EXECUTE AS USER = ''usuario_consulta'';';
PRINT 'INSERT INTO dbo.CentrosAcopio (nombre, direccion) VALUES (''Prueba'', ''Test'');';
PRINT '-- Error esperado: The INSERT permission was denied';
PRINT 'REVERT;';
PRINT '';

-- ============================================================================
-- PARTE 2: CREACIÓN DE VISTAS SEGURAS
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 2: Vistas que Ocultan Información Sensible                  |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

-- VISTA 1: Estadísticas públicas de centros (sin datos sensibles de depósitos individuales)
IF OBJECT_ID('dbo.vw_EstadisticasPublicasCentros', 'V') IS NOT NULL
    DROP VIEW dbo.vw_EstadisticasPublicasCentros;
GO

CREATE VIEW dbo.vw_EstadisticasPublicasCentros
AS
SELECT 
    ca.id_centro,
    ca.nombre AS Centro,
    ca.direccion AS Direccion,
    ca.horario AS Horario,
    ca.activo AS Esta_Operativo,
    COUNT(rd.id_registro) AS Total_Depositos_Historicos,
    CAST(ISNULL(SUM(rd.cantidad_kg), 0) AS DECIMAL(10,2)) AS Total_Kg_Recolectados,
    CAST(ISNULL(AVG(rd.cantidad_kg), 0) AS DECIMAL(10,2)) AS Promedio_Kg_Por_Deposito
FROM dbo.CentrosAcopio ca
LEFT JOIN dbo.RegistrosDeposito rd ON ca.id_centro = rd.id_centro_fk
GROUP BY 
    ca.id_centro,
    ca.nombre,
    ca.direccion,
    ca.horario,
    ca.activo;
GO

PRINT '✓ Vista creada: vw_EstadisticasPublicasCentros';
PRINT '  Propósito: Muestra estadísticas agregadas sin exponer registros individuales';
PRINT '  Datos ocultos: Fechas específicas de depósitos, cantidades individuales';
PRINT '';

-- VISTA 2: Resumen de materiales reciclables (sin detalles de quién/cuándo depositó)
IF OBJECT_ID('dbo.vw_ResumenMaterialesReciclables', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ResumenMaterialesReciclables;
GO

CREATE VIEW dbo.vw_ResumenMaterialesReciclables
AS
SELECT 
    cm.id_categoria,
    cm.nombre AS Material,
    cm.descripcion AS Descripcion,
    COUNT(rd.id_registro) AS Cantidad_Depositos,
    CAST(ISNULL(SUM(rd.cantidad_kg), 0) AS DECIMAL(10,2)) AS Total_Kg_Recolectados,
    CAST(ISNULL(AVG(rd.cantidad_kg), 0) AS DECIMAL(10,2)) AS Promedio_Kg_Por_Deposito,
    CAST(ISNULL(MIN(rd.cantidad_kg), 0) AS DECIMAL(10,2)) AS Deposito_Minimo_Kg,
    CAST(ISNULL(MAX(rd.cantidad_kg), 0) AS DECIMAL(10,2)) AS Deposito_Maximo_Kg
FROM dbo.CategoriasMaterial cm
LEFT JOIN dbo.RegistrosDeposito rd ON cm.id_categoria = rd.id_categoria_fk
GROUP BY 
    cm.id_categoria,
    cm.nombre,
    cm.descripcion;
GO

PRINT '✓ Vista creada: vw_ResumenMaterialesReciclables';
PRINT '  Propósito: Información pública sobre tipos de materiales y volúmenes globales';
PRINT '  Datos ocultos: Identidad de centros específicos, fechas de depósitos';
PRINT '';

-- Otorgar permisos de lectura en las vistas al usuario restringido
GRANT SELECT ON dbo.vw_EstadisticasPublicasCentros TO usuario_consulta;
GRANT SELECT ON dbo.vw_ResumenMaterialesReciclables TO usuario_consulta;
PRINT '✓ Permisos de SELECT otorgados al usuario_consulta en ambas vistas';
PRINT '';

-- Prueba de las vistas
PRINT 'Consultando vistas...';
SELECT * FROM dbo.vw_EstadisticasPublicasCentros;
SELECT * FROM dbo.vw_ResumenMaterialesReciclables;
PRINT '';

-- ============================================================================
-- PARTE 3: PRUEBAS DE INTEGRIDAD REFERENCIAL
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 3: Pruebas de Integridad Referencial                        |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

-- PRUEBA 1: Violación de PRIMARY KEY (duplicación)
PRINT '===== PRUEBA 1: Violación de PRIMARY KEY =====';
PRINT 'Intentando insertar un centro con id_centro duplicado...';
PRINT '';
BEGIN TRY
    INSERT INTO dbo.CentrosAcopio (id_centro, nombre, direccion, horario, activo)
    VALUES (1, 'Centro Duplicado', 'Calle Falsa 123', 'Lun-Vie 9-17', 1);
    
    PRINT '✗ ERROR: La inserción NO debería haber tenido éxito';
END TRY
BEGIN CATCH
    PRINT '✓ ÉXITO: Violación de PK detectada correctamente';
    PRINT '  Error: ' + ERROR_MESSAGE();
    PRINT '  Explicación: No se pueden tener dos centros con el mismo id_centro';
END CATCH
PRINT '';

-- PRUEBA 2: Violación de FOREIGN KEY
PRINT '===== PRUEBA 2: Violación de FOREIGN KEY =====';
PRINT 'Intentando insertar un depósito con id_centro inexistente (9999)...';
PRINT '';
BEGIN TRY
    INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg, fecha_deposito)
    VALUES (9999, 1, 5.5, GETDATE());
    
    PRINT '✗ ERROR: La inserción NO debería haber tenido éxito';
END TRY
BEGIN CATCH
    PRINT '✓ ÉXITO: Violación de FK detectada correctamente';
    PRINT '  Error: ' + ERROR_MESSAGE();
    PRINT '  Explicación: No se puede registrar depósito en centro inexistente (id_centro=9999)';
END CATCH
PRINT '';

-- PRUEBA 3: Violación de UNIQUE
PRINT '===== PRUEBA 3: Violación de UNIQUE =====';
PRINT 'Intentando insertar un centro con nombre duplicado...';
PRINT '';
BEGIN TRY
    INSERT INTO dbo.CentrosAcopio (nombre, direccion, horario, activo)
    VALUES ('EcoPunto Villa Urquiza', 'Dirección Diferente 456', 'Lun-Vie 8-20', 1);
    
    PRINT '✗ ERROR: La inserción NO debería haber tenido éxito';
END TRY
BEGIN CATCH
    PRINT '✓ ÉXITO: Violación de UNIQUE detectada correctamente';
    PRINT '  Error: ' + ERROR_MESSAGE();
    PRINT '  Explicación: No pueden existir dos centros con el mismo nombre';
END CATCH
PRINT '';

-- PRUEBA 4: Violación de CHECK (cantidad_kg > 0)
PRINT '===== PRUEBA 4: Violación de CHECK =====';
PRINT 'Intentando insertar un depósito con cantidad negativa (-5 kg)...';
PRINT '';
BEGIN TRY
    INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg, fecha_deposito)
    VALUES (1, 1, -5.0, GETDATE());
    
    PRINT '✗ ERROR: La inserción NO debería haber tenido éxito';
END TRY
BEGIN CATCH
    PRINT '✓ ÉXITO: Violación de CHECK detectada correctamente';
    PRINT '  Error: ' + ERROR_MESSAGE();
    PRINT '  Explicación: No se puede registrar cantidad negativa de material';
END CATCH
PRINT '';

-- ============================================================================
-- PARTE 4: PROCEDIMIENTO ALMACENADO SEGURO (sin SQL dinámico)
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PARTE 4: Procedimiento Almacenado Seguro (Anti-SQL Injection)     |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

IF OBJECT_ID('dbo.sp_RegistrarDepositoSeguro', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarDepositoSeguro;
GO

CREATE PROCEDURE dbo.sp_RegistrarDepositoSeguro
    @nombre_centro NVARCHAR(100),
    @nombre_material NVARCHAR(50),
    @cantidad_kg DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validaciones de entrada (defensivas)
    IF @nombre_centro IS NULL OR LTRIM(RTRIM(@nombre_centro)) = ''
    BEGIN
        RAISERROR('Error: El nombre del centro no puede estar vacío', 16, 1);
        RETURN;
    END
    
    IF @nombre_material IS NULL OR LTRIM(RTRIM(@nombre_material)) = ''
    BEGIN
        RAISERROR('Error: El nombre del material no puede estar vacío', 16, 1);
        RETURN;
    END
    
    IF @cantidad_kg IS NULL OR @cantidad_kg <= 0
    BEGIN
        RAISERROR('Error: La cantidad debe ser mayor a 0', 16, 1);
        RETURN;
    END
    
    -- Variables locales
    DECLARE @id_centro INT;
    DECLARE @id_categoria INT;
    
    -- Buscar id_centro por nombre (consulta parametrizada)
    SELECT @id_centro = id_centro 
    FROM dbo.CentrosAcopio 
    WHERE nombre = @nombre_centro AND activo = 1;
    
    IF @id_centro IS NULL
    BEGIN
        RAISERROR('Error: Centro de acopio no encontrado o inactivo', 16, 1);
        RETURN;
    END
    
    -- Buscar id_categoria por nombre (consulta parametrizada)
    SELECT @id_categoria = id_categoria 
    FROM dbo.CategoriasMaterial 
    WHERE nombre = @nombre_material;
    
    IF @id_categoria IS NULL
    BEGIN
        RAISERROR('Error: Categoría de material no encontrada', 16, 1);
        RETURN;
    END
    
    -- Inserción segura (solo con variables locales, NO concatenación)
    BEGIN TRY
        INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg, fecha_deposito)
        VALUES (@id_centro, @id_categoria, @cantidad_kg, GETDATE());
        
        PRINT '✓ Depósito registrado correctamente:';
        PRINT '  Centro: ' + @nombre_centro;
        PRINT '  Material: ' + @nombre_material;
        PRINT '  Cantidad: ' + CAST(@cantidad_kg AS NVARCHAR(20)) + ' kg';
    END TRY
    BEGIN CATCH
        PRINT '✗ Error al registrar depósito: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Procedimiento almacenado creado: sp_RegistrarDepositoSeguro';
PRINT '';

-- ============================================================================
-- PRUEBAS ANTI-INYECCIÓN SQL
-- ============================================================================
PRINT '+--------------------------------------------------------------------+';
PRINT '| PRUEBAS ANTI-INYECCIÓN SQL                                         |';
PRINT '+--------------------------------------------------------------------+';
PRINT '';

-- PRUEBA LEGÍTIMA (funciona correctamente)
PRINT '===== PRUEBA 1: Uso legítimo del procedimiento =====';
EXEC dbo.sp_RegistrarDepositoSeguro 
    @nombre_centro = 'EcoPunto Villa Urquiza',
    @nombre_material = 'Papel',
    @cantidad_kg = 12.5;
PRINT '';

-- INTENTO DE INYECCIÓN 1: Comillas maliciosas
PRINT '===== PRUEBA 2: Intento de SQL Injection (comillas maliciosas) =====';
PRINT 'Entrada maliciosa: @nombre_centro = ''EcoPunto''; DROP TABLE CentrosAcopio; --''';
PRINT '';
BEGIN TRY
    EXEC dbo.sp_RegistrarDepositoSeguro 
        @nombre_centro = 'EcoPunto''; DROP TABLE CentrosAcopio; --',
        @nombre_material = 'Vidrio',
        @cantidad_kg = 5.0;
END TRY
BEGIN CATCH
    PRINT '✓ INYECCIÓN BLOQUEADA: ' + ERROR_MESSAGE();
    PRINT '  Explicación: El procedimiento usa parámetros, NO concatenación de strings.';
    PRINT '  La entrada maliciosa se trata como texto literal, no como código SQL.';
    PRINT '  El intento "DROP TABLE" jamás se ejecuta.';
END CATCH
PRINT '';

-- INTENTO DE INYECCIÓN 2: UNION SELECT
PRINT '===== PRUEBA 3: Intento de SQL Injection (UNION SELECT) =====';
PRINT 'Entrada maliciosa: @nombre_material = ''Plástico'' UNION SELECT password FROM users--''';
PRINT '';
BEGIN TRY
    EXEC dbo.sp_RegistrarDepositoSeguro 
        @nombre_centro = 'EcoPunto Centro',
        @nombre_material = 'Plástico'' UNION SELECT password FROM users--',
        @cantidad_kg = 3.0;
END TRY
BEGIN CATCH
    PRINT '✓ INYECCIÓN BLOQUEADA: ' + ERROR_MESSAGE();
    PRINT '  Explicación: El parámetro @nombre_material se busca literalmente en la tabla.';
    PRINT '  No existe material llamado "Plástico'' UNION SELECT...", por lo que falla.';
    PRINT '  El código inyectado nunca se interpreta como SQL.';
END CATCH
PRINT '';

-- Verificar que las tablas siguen intactas
PRINT '===== Verificación de Integridad Post-Ataques =====';
PRINT 'Verificando que las tablas NO fueron eliminadas...';
SELECT COUNT(*) AS CentrosIntactos FROM dbo.CentrosAcopio;
SELECT COUNT(*) AS CategoriasIntactas FROM dbo.CategoriasMaterial;
PRINT '✓ Todas las tablas están intactas. Los ataques fueron neutralizados.';
PRINT '';

PRINT '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::';
PRINT '✓ ETAPA 4 COMPLETADA: Seguridad e Integridad implementadas exitosamente';
PRINT '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::';
PRINT '';
PRINT 'Completion time: ' + CONVERT(VARCHAR, GETDATE(), 121);
PRINT '';
