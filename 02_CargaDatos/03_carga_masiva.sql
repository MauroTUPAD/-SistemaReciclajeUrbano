/******************************************************************************
 TFI - Bases de Datos I
 Script: 03_carga_masiva_FINAL.sql
 
 Descripción:
 Versión final y robusta.
 - Utiliza un generador de números simple (sys.all_objects) para
   garantizar 10.000 filas.
 - Corrige el error de "Arithmetic overflow" en el PRINT final.
 
******************************************************************************/

USE [SistemaReciclajeUrbano];
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '  ETAPA 2: CARGA MASIVA DE DATOS TRANSACCIONALES (VERSIÓN FINAL)';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';

------------------------------------------------------------
-- PASO 1: CONFIGURACIÓN
------------------------------------------------------------
DECLARE @N_Rows_To_Insert INT = 10000;  -- Volumen objetivo

PRINT '→ Configuración:';
PRINT '  Registros a generar: ' + CAST(@N_Rows_To_Insert AS NVARCHAR(10));
PRINT '';

------------------------------------------------------------
-- PASO 2: LECTURA DE IDs VÁLIDOS DESDE LOS CATÁLOGOS
------------------------------------------------------------
PRINT '→ Leyendo catálogos maestros...';

DECLARE @ValidCategoriasIDs TABLE (
    rn INT PRIMARY KEY, id_categoria INT
);
DECLARE @ValidCentrosIDs TABLE (
    rn INT PRIMARY KEY, id_centro INT
);

INSERT INTO @ValidCategoriasIDs (rn, id_categoria)
SELECT 
    ROW_NUMBER() OVER(ORDER BY id_categoria) AS rn, 
    id_categoria
FROM dbo.CategoriasMaterial
WHERE activo = 1;

INSERT INTO @ValidCentrosIDs (rn, id_centro)
SELECT 
    ROW_NUMBER() OVER(ORDER BY id_centro) AS rn, 
    id_centro
FROM dbo.CentrosAcopio
WHERE activo = 1;

DECLARE @TotalCentros INT = (SELECT COUNT(*) FROM @ValidCentrosIDs);
DECLARE @TotalCategorias INT = (SELECT COUNT(*) FROM @ValidCategoriasIDs);

PRINT '  ✓ Categorías activas encontradas: ' + CAST(@TotalCategorias AS NVARCHAR(10));
PRINT '  ✓ Centros activos encontrados: ' + CAST(@TotalCentros AS NVARCHAR(10));
PRINT '';

------------------------------------------------------------
-- PASO 3: VERIFICACIÓN DE PREREQUISITOS
------------------------------------------------------------
IF @TotalCentros = 0 OR @TotalCategorias = 0
BEGIN
    RAISERROR('✗ ERROR: Los catálogos están vacíos. Ejecute 02_catalogo.sql primero.', 16, 1);
    RETURN;
END

PRINT '→ Prerequisitos cumplidos. Iniciando generación...';
PRINT '';

------------------------------------------------------------
-- PASO 4: LIMPIEZA DE DATOS ANTERIORES
------------------------------------------------------------
PRINT '→ Limpiando tabla RegistrosDeposito...';

DECLARE @FilasExistentes INT = 0;
SELECT @FilasExistentes = COUNT(*) FROM dbo.RegistrosDeposito WITH (NOLOCK);

IF @FilasExistentes > 0
BEGIN
    TRUNCATE TABLE dbo.RegistrosDeposito;
    PRINT '  ✓ Se eliminaron ' + CAST(@FilasExistentes AS NVARCHAR(10)) + ' filas existentes';
END
ELSE
BEGIN
    PRINT '  ✓ La tabla estaba vacía';
END

PRINT '';

------------------------------------------------------------
-- PASO 5: GENERACIÓN MASIVA CON CTE
------------------------------------------------------------
PRINT '→ Generando ' + CAST(@N_Rows_To_Insert AS NVARCHAR(10)) + ' registros...';
PRINT '  (Esto puede tomar unos segundos)';
PRINT '';

DECLARE @TiempoInicio DATETIME2 = SYSDATETIME();

;WITH
-- ==================================================================
-- INICIO DE SECCIÓN CORREGIDA: Generador de Números (Versión 3)
-- Usamos sys.all_objects. Es más simple y robusto que la CTE L0-L4.
-- (Requiere permisos de VIEW DEFINITION, que usualmente se tienen)
Numeros(n) AS (
    SELECT TOP (@N_Rows_To_Insert)
        ROW_NUMBER() OVER(ORDER BY a.object_id)
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
-- FIN DE SECCIÓN CORREGIDA
-- ==================================================================

-- Generador de datos aleatorios
DatosAleatorios AS (
    SELECT
        (ABS(CHECKSUM(NEWID())) % @TotalCentros) + 1 AS centro_rn,
        (ABS(CHECKSUM(NEWID())) % @TotalCategorias) + 1 AS categoria_rn,
        CAST(
            ROUND((RAND(CHECKSUM(NEWID())) * 49.90) + 0.10, 2) 
            AS DECIMAL(10,2)
        ) AS cantidad_kg,
        DATEADD(
            second, 
            (ABS(CHECKSUM(NEWID())) % 31536000) * -1,
            SYSDATETIME()
        ) AS fecha_deposito
    FROM Numeros
)
-- Inserción final con JOIN a los IDs válidos
INSERT INTO dbo.RegistrosDeposito (
    id_centro_fk,
    id_categoria_fk,
    cantidad_kg,
    fecha_deposito
)
SELECT
    c.id_centro,
    cat.id_categoria,
    da.cantidad_kg,
    da.fecha_deposito
FROM DatosAleatorios da
INNER JOIN @ValidCentrosIDs c ON da.centro_rn = c.rn
INNER JOIN @ValidCategoriasIDs cat ON da.categoria_rn = cat.rn;

DECLARE @TiempoFin DATETIME2 = SYSDATETIME();
DECLARE @TiempoTotal INT = DATEDIFF(millisecond, @TiempoInicio, @TiempoFin);

PRINT '  ✓ Generación completada en ' + CAST(@TiempoTotal AS NVARCHAR(10)) + ' ms';
PRINT '';

------------------------------------------------------------
-- PASO 6: RESUMEN FINAL
------------------------------------------------------------
DECLARE @RegistrosGenerados INT = 0;
SELECT @RegistrosGenerados = COUNT(*) FROM dbo.RegistrosDeposito WITH (NOLOCK);

PRINT '████████████████████████████████████████████████████████████████';
PRINT '  RESUMEN DE CARGA MASIVA:';
PRINT '  - Registros generados: ' + CAST(@RegistrosGenerados AS NVARCHAR(10));
PRINT '  - Tiempo de ejecución: ' + CAST(@TiempoTotal AS NVARCHAR(10)) + ' ms';

IF @TiempoTotal > 0
BEGIN
    -- ==================================================================
    -- INICIO DE SECCIÓN CORREGIDA: Error de Overflow
    -- Se castea a DECIMAL(10,2) ANTES de convertir a NVARCHAR.
    DECLARE @Throughput DECIMAL(10, 2) = (@RegistrosGenerados * 1.0) / (@TiempoTotal / 1000.0);
    PRINT '  - Throughput: ' + CAST(@Throughput AS NVARCHAR(20)) + ' filas/segundo';
    -- FIN DE SECCIÓN CORREGIDA
    -- ==================================================================
END
ELSE
BEGIN
    PRINT '  - Throughput: N/A (ejecución demasiado rápida)';
END

PRINT '████████████████████████████████████████████████████████████████';

IF @RegistrosGenerados = @N_Rows_To_Insert
BEGIN
    PRINT '✓ CARGA MASIVA COMPLETADA EXITOSAMENTE';
END
ELSE
BEGIN
    PRINT '✗ ADVERTENCIA: La carga se completó, pero el conteo no coincide (' + CAST(@RegistrosGenerados AS NVARCHAR(10)) + ' vs ' + CAST(@N_Rows_To_Insert AS NVARCHAR(10)) + ')';
END

PRINT '';
PRINT 'Siguiente paso: Ejecutar 04_verificaciones.sql para validar';
PRINT 'la integridad y consistencia de los datos generados.';
PRINT '';
GO
