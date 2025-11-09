/******************************************************************************
 TFI - Bases de Datos I
 Script: 05_consultas_avanzadas.sql (T-SQL / SQL Server)
 
 ETAPA 3: CONSULTAS AVANZADAS Y REPORTES
 
 Sistema: Gestión de Reciclaje Urbano
 Autor: Mauro Ezequiel Ponce
 Fecha: Noviembre 2025
 
 Descripción:
 Este script contiene 4 consultas SQL avanzadas que agregan valor al sistema:
 - 2 consultas con JOIN
 - 1 consulta con GROUP BY + HAVING
 - 1 consulta con subconsulta (CTE con ROW_NUMBER)
 
 Cada consulta está documentada con su utilidad práctica para el negocio.
 
******************************************************************************/

USE [SistemaReciclajeUrbano];
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '  ETAPA 3: CONSULTAS AVANZADAS Y REPORTES';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';

------------------------------------------------------------
-- CONSULTA 1: JOIN + GROUP BY
-- Tipo: Igualdad + Agregación
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA 1: Ranking de Materiales por Kilogramos Totales      │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';
PRINT 'Utilidad Práctica:';
PRINT '  Este reporte permite a los gestores identificar qué materiales';
PRINT '  son los más recolectados, para:';
PRINT '  - Optimizar campañas de concientización (foco en materiales menos recolectados)';
PRINT '  - Planificar capacidad de almacenamiento por tipo de material';
PRINT '  - Negociar contratos con recicladores según volúmenes reales';
PRINT '';

SELECT
    cm.nombre AS Material,
    COUNT(rd.id_registro) AS Cantidad_Depositos,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales,
    CAST(AVG(rd.cantidad_kg) AS DECIMAL(10,2)) AS Promedio_Kg_Por_Deposito,
    CAST(MIN(rd.cantidad_kg) AS DECIMAL(10,2)) AS Minimo_Kg,
    CAST(MAX(rd.cantidad_kg) AS DECIMAL(10,2)) AS Maximo_Kg
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.id_categoria, cm.nombre
ORDER BY Kilos_Totales DESC;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA 2: JOIN MÚLTIPLE + GROUP BY
-- Tipo: JOIN + Agregación Temporal
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA 2: Resumen Mensual por Centro de Acopio              │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';
PRINT 'Utilidad Práctica:';
PRINT '  Este reporte de tendencias temporales permite:';
PRINT '  - Identificar estacionalidad en la recolección (meses altos/bajos)';
PRINT '  - Detectar centros con caída de actividad (requieren atención)';
PRINT '  - Proyectar necesidades de personal y logística por mes';
PRINT '  - Generar KPIs mensuales para reportes gerenciales';
PRINT '';

SELECT
    ca.nombre AS Centro,
    YEAR(rd.fecha_deposito) AS Anio,
    MONTH(rd.fecha_deposito) AS Mes,
    COUNT(rd.id_registro) AS Depositos_Del_Mes,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Del_Mes,
    COUNT(DISTINCT rd.id_categoria_fk) AS Categorias_Distintas
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CentrosAcopio ca ON rd.id_centro_fk = ca.id_centro
GROUP BY 
    ca.id_centro,
    ca.nombre, 
    YEAR(rd.fecha_deposito), 
    MONTH(rd.fecha_deposito)
ORDER BY 
    ca.nombre, 
    Anio DESC, 
    Mes DESC;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA 3: GROUP BY + HAVING
-- Tipo: Filtro POST-agregación
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA 3: Alertas de Centros con Baja Actividad Reciente    │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';
PRINT 'Utilidad Práctica:';
PRINT '  Este reporte de "alerta temprana" identifica centros que:';
PRINT '  - Recibieron MENOS de 100 depósitos en los últimos 30 días';
PRINT '  - Pueden requerir mantenimiento, promoción o reapertura';
PRINT '  - Necesitan auditoría (¿están operativos? ¿horarios correctos?)';
PRINT '';
PRINT '  Acción sugerida: Inspección física + campaña de comunicación local';
PRINT '';

SELECT
    ca.nombre AS Centro_Con_Baja_Actividad,
    ca.direccion,
    ca.horario,
    COUNT(rd.id_registro) AS Depositos_Ultimos_30_Dias,
    CAST(SUM(rd.cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Ultimos_30_Dias,
    CAST(GETDATE() AS DATE) AS Fecha_Consulta
FROM dbo.CentrosAcopio ca
LEFT JOIN dbo.RegistrosDeposito rd ON ca.id_centro = rd.id_centro_fk
    AND rd.fecha_deposito >= DATEADD(DAY, -30, GETDATE())
WHERE ca.activo = 1  -- Solo centros que deberían estar operativos
GROUP BY 
    ca.id_centro,
    ca.nombre, 
    ca.direccion, 
    ca.horario
HAVING 
    COUNT(rd.id_registro) < 100  -- Umbral de alerta
ORDER BY 
    Depositos_Ultimos_30_Dias ASC;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- CONSULTA 4: SUBCONSULTA CON CTE Y ROW_NUMBER
-- Tipo: Ranking por partición (último depósito por centro)
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ CONSULTA 4: Último Depósito Registrado en Cada Centro         │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';
PRINT 'Utilidad Práctica:';
PRINT '  Este reporte de "estado actual" permite:';
PRINT '  - Verificar cuándo fue la última actividad de cada centro';
PRINT '  - Detectar centros "dormidos" (sin actividad por muchos días)';
PRINT '  - Auditar la operación diaria del sistema';
PRINT '  - Generar dashboard en tiempo real con "última actualización"';
PRINT '';

;WITH UltimosDepositos AS (
    SELECT
        rd.id_registro,
        rd.fecha_deposito,
        rd.cantidad_kg,
        ca.nombre AS Centro,
        ca.direccion,
        cm.nombre AS Material,
        -- ROW_NUMBER particiona por centro y ordena por fecha DESC
        -- El registro con rn=1 es el MÁS RECIENTE de ese centro
        ROW_NUMBER() OVER (
            PARTITION BY rd.id_centro_fk 
            ORDER BY rd.fecha_deposito DESC
        ) AS rn,
        -- Calculamos hace cuántas horas fue el depósito
        DATEDIFF(HOUR, rd.fecha_deposito, GETDATE()) AS Horas_Desde_Deposito
    FROM dbo.RegistrosDeposito rd
    INNER JOIN dbo.CentrosAcopio ca ON rd.id_centro_fk = ca.id_centro
    INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
    WHERE ca.activo = 1
)
SELECT
    Centro,
    direccion AS Direccion,
    Material AS Ultimo_Material_Depositado,
    cantidad_kg AS Cantidad_Kg,
    fecha_deposito AS Fecha_Ultimo_Deposito,
    Horas_Desde_Deposito,
    CASE 
        WHEN Horas_Desde_Deposito > 168 THEN 'ALERTA: Sin actividad >7 días'
        WHEN Horas_Desde_Deposito > 72 THEN 'Advertencia: Sin actividad >3 días'
        ELSE 'Normal'
    END AS Estado_Operativo
FROM UltimosDepositos
WHERE rn = 1  -- Solo el registro más reciente por centro
ORDER BY Horas_Desde_Deposito DESC;

PRINT '';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '✓ CONSULTAS AVANZADAS EJECUTADAS EXITOSAMENTE';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';
GO

/******************************************************************************
 FIN DEL SCRIPT: 05_consultas_avanzadas.sql
 
 RESUMEN DE CONSULTAS:
 
 1. Ranking de Materiales (JOIN + GROUP BY)
    → Identifica materiales más/menos recolectados
    
 2. Resumen Mensual por Centro (JOIN múltiple + GROUP BY temporal)
    → Detecta tendencias y estacionalidad
    
 3. Alertas de Baja Actividad (GROUP BY + HAVING)
    → Identifica centros que requieren atención
    
 4. Último Depósito por Centro (CTE + ROW_NUMBER + SUBCONSULTA)
    → Monitoreo en tiempo real del estado operativo
    
 Siguiente paso: Ejecutar 06_vistas.sql para encapsular lógica compleja.
******************************************************************************/
