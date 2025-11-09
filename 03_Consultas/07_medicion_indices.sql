/******************************************************************************
 TFI - Bases de Datos I
 Script: 07_medicion_indices.sql (T-SQL / SQL Server)
 
 ETAPA 3: MEDICIÓN COMPARATIVA CON/SIN ÍNDICES
 
 Sistema: Gestión de Reciclaje Urbano
 Autor: Mauro Ezequiel Ponce
 Fecha: Noviembre 2025
 
 Descripción:
 Este script mide empíricamente el impacto de los índices NONCLUSTERED
 en el rendimiento de consultas típicas.
 
 Metodología:
 1. Se ejecutan 3 consultas representativas (Igualdad, Rango, JOIN)
 2. Cada consulta se ejecuta 3 veces CON índices
 3. Se eliminan los índices
 4. Cada consulta se ejecuta 3 veces SIN índices
 5. Se comparan los tiempos y lecturas lógicas (STATISTICS IO)
 
 Objetivo Pedagógico:
 Demostrar que en volúmenes pequeños (~10K filas), el beneficio de los
 índices puede ser marginal o nulo, porque el Query Optimizer prefiere
 Table Scans cuando toda la tabla cabe en pocas páginas de memoria.
 
******************************************************************************/

USE [SistemaReciclajeUrbano];
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '  ETAPA 3: MEDICIÓN COMPARATIVA DE ÍNDICES';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';

------------------------------------------------------------
-- PASO 0: CONFIGURACIÓN DE ESTADÍSTICAS
------------------------------------------------------------
PRINT '→ Configurando estadísticas de rendimiento...';

-- Activar estadísticas de E/S (lecturas lógicas/físicas)
SET STATISTICS IO ON;

-- Activar estadísticas de tiempo
SET STATISTICS TIME ON;

PRINT '  ✓ STATISTICS IO ON';
PRINT '  ✓ STATISTICS TIME ON';
PRINT '';

------------------------------------------------------------
-- PASO 1: VERIFICAR ÍNDICES EXISTENTES
------------------------------------------------------------
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'FASE 1: MEDICIÓN CON ÍNDICES';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '→ Índices existentes en RegistrosDeposito:';

SELECT 
    i.name AS Indice,
    i.type_desc AS Tipo,
    COL_NAME(ic.object_id, ic.column_id) AS Columna
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('dbo.RegistrosDeposito')
  AND i.name IS NOT NULL
ORDER BY i.name, ic.key_ordinal;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA A: IGUALDAD (WHERE col = valor)
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA A: Igualdad (WHERE id_centro_fk = 1)                 │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '  Tipo: Búsqueda por igualdad en columna con FK (indexada)';
PRINT '  Índice disponible: IX_RegistrosDeposito_Centro';
PRINT '';

-- Limpiar caché para medición justa
DBCC DROPCLEANBUFFERS;  -- Limpia el buffer pool
DBCC FREEPROCCACHE;     -- Limpia el plan cache
CHECKPOINT;             -- Fuerza escritura de páginas sucias

-- Ejecución 1
PRINT '  Corrida 1/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE id_centro_fk = 1;

-- Ejecución 2
PRINT '  Corrida 2/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE id_centro_fk = 1;

-- Ejecución 3
PRINT '  Corrida 3/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE id_centro_fk = 1;

PRINT '';
PRINT '  → Anotar los valores de "logical reads" de las 3 corridas';
PRINT '  → Calcular la mediana manualmente';
PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA B: RANGO (WHERE fecha BETWEEN)
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA B: Rango (WHERE fecha >= fecha_inicio)               │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '  Tipo: Búsqueda por rango de fechas';
PRINT '  Índice disponible: IX_RegistrosDeposito_Fecha';
PRINT '';

-- Limpiar caché
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
CHECKPOINT;

-- Ejecución 1
PRINT '  Corrida 1/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE fecha_deposito >= DATEADD(MONTH, -1, GETDATE());

-- Ejecución 2
PRINT '  Corrida 2/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE fecha_deposito >= DATEADD(MONTH, -1, GETDATE());

-- Ejecución 3
PRINT '  Corrida 3/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE fecha_deposito >= DATEADD(MONTH, -1, GETDATE());

PRINT '';
PRINT '  → Anotar los valores de "logical reads" de las 3 corridas';
PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA C: JOIN
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA C: JOIN con Agregación                               │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '  Tipo: JOIN entre tabla de hechos y dimensión + GROUP BY';
PRINT '  Índice disponible: IX_RegistrosDeposito_Categoria';
PRINT '';

-- Limpiar caché
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
CHECKPOINT;

-- Ejecución 1
PRINT '  Corrida 1/3...';
SELECT 
    cm.nombre AS Categoria,
    COUNT(rd.id_registro) AS Total_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

-- Ejecución 2
PRINT '  Corrida 2/3...';
SELECT 
    cm.nombre AS Categoria,
    COUNT(rd.id_registro) AS Total_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

-- Ejecución 3
PRINT '  Corrida 3/3...';
SELECT 
    cm.nombre AS Categoria,
    COUNT(rd.id_registro) AS Total_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

PRINT '';
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'FIN DE FASE 1: Mediciones CON índices completadas';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '¡¡¡IMPORTANTE!!!';
PRINT 'COPIAR Y PEGAR TODO EL OUTPUT DEL PANEL DE MENSAJES A UN ARCHIVO DE TEXTO';
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'FASE 2: ELIMINACIÓN DE ÍNDICES';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '→ Eliminando índices NONCLUSTERED...';

-- Eliminar índices secundarios (mantener el PK Clustered)
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RegistrosDeposito_Centro' AND object_id = OBJECT_ID('dbo.RegistrosDeposito'))
BEGIN
    DROP INDEX IX_RegistrosDeposito_Centro ON dbo.RegistrosDeposito;
    PRINT '  ✓ IX_RegistrosDeposito_Centro eliminado';
END

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RegistrosDeposito_Categoria' AND object_id = OBJECT_ID('dbo.RegistrosDeposito'))
BEGIN
    DROP INDEX IX_RegistrosDeposito_Categoria ON dbo.RegistrosDeposito;
    PRINT '  ✓ IX_RegistrosDeposito_Categoria eliminado';
END

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RegistrosDeposito_Fecha' AND object_id = OBJECT_ID('dbo.RegistrosDeposito'))
BEGIN
    DROP INDEX IX_RegistrosDeposito_Fecha ON dbo.RegistrosDeposito;
    PRINT '  ✓ IX_RegistrosDeposito_Fecha eliminado';
END

PRINT '';
PRINT '→ Verificando índices restantes (solo debería quedar el PK):';

SELECT 
    i.name AS Indice,
    i.type_desc AS Tipo
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.RegistrosDeposito')
  AND i.name IS NOT NULL;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- FASE 3: REPETIR MEDICIONES SIN ÍNDICES
------------------------------------------------------------
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'FASE 3: MEDICIÓN SIN ÍNDICES';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';

------------------------------------------------------------
-- CONSULTA A (Sin índice)
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA A: Igualdad (SIN índice en id_centro_fk)             │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';

-- Limpiar caché
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
CHECKPOINT;

-- Ejecución 1
PRINT '  Corrida 1/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE id_centro_fk = 1;

-- Ejecución 2
PRINT '  Corrida 2/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE id_centro_fk = 1;

-- Ejecución 3
PRINT '  Corrida 3/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE id_centro_fk = 1;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA B (Sin índice)
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA B: Rango (SIN índice en fecha_deposito)              │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';

-- Limpiar caché
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
CHECKPOINT;

-- Ejecución 1
PRINT '  Corrida 1/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE fecha_deposito >= DATEADD(MONTH, -1, GETDATE());

-- Ejecución 2
PRINT '  Corrida 2/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE fecha_deposito >= DATEADD(MONTH, -1, GETDATE());

-- Ejecución 3
PRINT '  Corrida 3/3...';
SELECT 
    COUNT(*) AS Total_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito
WHERE fecha_deposito >= DATEADD(MONTH, -1, GETDATE());

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA C (Sin índice)
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA C: JOIN (SIN índice en id_categoria_fk)              │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';

-- Limpiar caché
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
CHECKPOINT;

-- Ejecución 1
PRINT '  Corrida 1/3...';
SELECT 
    cm.nombre AS Categoria,
    COUNT(rd.id_registro) AS Total_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

-- Ejecución 2
PRINT '  Corrida 2/3...';
SELECT 
    cm.nombre AS Categoria,
    COUNT(rd.id_registro) AS Total_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

-- Ejecución 3
PRINT '  Corrida 3/3...';
SELECT 
    cm.nombre AS Categoria,
    COUNT(rd.id_registro) AS Total_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

PRINT '';
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'FIN DE FASE 3: Mediciones SIN índices completadas';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';

------------------------------------------------------------
-- FASE 4: RESTAURAR ÍNDICES
------------------------------------------------------------
PRINT '════════════════════════════════════════════════════════════════';
PRINT 'FASE 4: RESTAURACIÓN DE ÍNDICES';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';
PRINT '→ Recreando índices...';

-- Recrear índices
CREATE NONCLUSTERED INDEX IX_RegistrosDeposito_Centro
    ON dbo.RegistrosDeposito(id_centro_fk)
    INCLUDE (cantidad_kg, fecha_deposito);

CREATE NONCLUSTERED INDEX IX_RegistrosDeposito_Categoria
    ON dbo.RegistrosDeposito(id_categoria_fk)
    INCLUDE (cantidad_kg, fecha_deposito);

CREATE NONCLUSTERED INDEX IX_RegistrosDeposito_Fecha
    ON dbo.RegistrosDeposito(fecha_deposito)
    INCLUDE (id_centro_fk, id_categoria_fk, cantidad_kg);

PRINT '  ✓ Índices recreados correctamente';
PRINT '';

------------------------------------------------------------
-- DESACTIVAR ESTADÍSTICAS
------------------------------------------------------------
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

PRINT '════════════════════════════════════════════════════════════════';
PRINT '✓ MEDICIÓN COMPARATIVA COMPLETADA';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';
PRINT 'PRÓXIMOS PASOS:';
PRINT '1. Revisar el output completo del panel de mensajes';
PRINT '2. Extraer los valores de "logical reads" de cada corrida';
PRINT '3. Calcular la mediana de las 3 corridas para cada consulta';
PRINT '4. Completar la tabla de comparación en el informe del PDF';
PRINT '';
PRINT 'NOTA IMPORTANTE:';
PRINT 'Con un volumen de ~10.000 filas, es ESPERADO que el beneficio';
PRINT 'de los índices sea marginal o nulo. El Query Optimizer de SQL Server';
PRINT 'puede preferir Table Scans porque la tabla completa cabe en pocas';
PRINT 'páginas de memoria. Los índices muestran su verdadero valor con';
PRINT 'volúmenes de 100.000+ filas.';
PRINT '';
GO

/******************************************************************************
 FIN DEL SCRIPT: 07_medicion_indices.sql
 
 METODOLOGÍA APLICADA:
 
 1. Medición CON índices (3 consultas × 3 corridas = 9 mediciones)
 2. Eliminación temporal de índices NONCLUSTERED
 3. Medición SIN índices (3 consultas × 3 corridas = 9 mediciones)
 4. Restauración de índices
 
 MÉTRICAS CLAVE:
 - logical reads: Número de páginas de 8KB leídas desde el buffer pool
 - CPU time: Tiempo de CPU consumido
 - elapsed time: Tiempo total transcurrido (incluye esperas)
 
 ANÁLISIS ESPERADO:
 Con ~10K filas, se espera que:
 - Consulta A (igualdad): Diferencia mínima (~48 páginas con o sin índice)
 - Consulta B (rango): Diferencia mínima (el rango incluye gran parte de la tabla)
 - Consulta C (JOIN): Diferencia moderada (el JOIN puede beneficiarse del índice)
 
 CONCLUSIÓN PEDAGÓGICA:
 Los índices NO son una solución mágica. Su diseño debe basarse en:
 - Volumen de datos (crítico en tablas >100K filas)
 - Selectividad de las consultas (consultas que filtran <5% de filas)
 - Frecuencia de uso (columnas consultadas frecuentemente)
 
******************************************************************************/
