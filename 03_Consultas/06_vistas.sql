/******************************************************************************
 TFI - Bases de Datos I
 Script: 06_vistas.sql (T-SQL / SQL Server)
 
 ETAPA 3: CREACIÓN DE VISTAS ÚTILES
 
 Sistema: Gestión de Reciclaje Urbano
 Autor: Mauro Ezequiel Ponce
 Fecha: Noviembre 2025
 
 Descripción:
 Este script crea vistas que simplifican el acceso a datos complejos,
 encapsulando JOINs y lógica de negocio para:
 - Facilitar consultas desde aplicaciones (Java, Power BI, etc.)
 - Reducir errores de programación (JOINs incorrectos)
 - Mejorar mantenibilidad del código
 
******************************************************************************/

USE [SistemaReciclajeUrbano];
GO

SET NOCOUNT ON;
GO

PRINT '';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '  ETAPA 3: CREACIÓN DE VISTAS';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';

------------------------------------------------------------
-- VISTA PRINCIPAL: Depósitos con Información Completa
------------------------------------------------------------
PRINT '→ Creando vista: V_Depositos_Detallados';
PRINT '';

-- DROP si existe (para hacer el script idempotente)
IF OBJECT_ID('dbo.V_Depositos_Detallados', 'V') IS NOT NULL
    DROP VIEW dbo.V_Depositos_Detallados;
GO

CREATE VIEW dbo.V_Depositos_Detallados
AS
SELECT
    -- Columnas de la tabla de hechos
    rd.id_registro,
    rd.cantidad_kg,
    rd.fecha_deposito,
    rd.observaciones,
    
    -- Información del Centro (dimensión)
    ca.id_centro,
    ca.nombre AS centro_nombre,
    ca.direccion AS centro_direccion,
    ca.codigo_postal AS centro_codigo_postal,
    ca.horario AS centro_horario,
    
    -- Información de la Categoría (dimensión)
    cm.id_categoria,
    cm.nombre AS categoria_nombre,
    cm.descripcion AS categoria_descripcion,
    
    -- Campos calculados útiles
    CAST(rd.fecha_deposito AS DATE) AS fecha_solo,
    YEAR(rd.fecha_deposito) AS anio,
    MONTH(rd.fecha_deposito) AS mes,
    DATEPART(QUARTER, rd.fecha_deposito) AS trimestre,
    DATENAME(WEEKDAY, rd.fecha_deposito) AS dia_semana,
    
    -- Clasificación de cantidad
    CASE 
        WHEN rd.cantidad_kg < 10 THEN 'Pequeño (< 10 kg)'
        WHEN rd.cantidad_kg < 25 THEN 'Mediano (10-25 kg)'
        WHEN rd.cantidad_kg < 40 THEN 'Grande (25-40 kg)'
        ELSE 'Muy Grande (>= 40 kg)'
    END AS tamano_deposito
    
FROM dbo.RegistrosDeposito rd
INNER JOIN dbo.CentrosAcopio ca ON rd.id_centro_fk = ca.id_centro
INNER JOIN dbo.CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria;
GO

PRINT '  ✓ Vista V_Depositos_Detallados creada';
PRINT '';

------------------------------------------------------------
-- PRUEBA DE LA VISTA
------------------------------------------------------------
PRINT '→ Probando la vista (TOP 10 registros más recientes):';
PRINT '';

SELECT TOP 10
    id_registro,
    fecha_solo,
    centro_nombre,
    categoria_nombre,
    cantidad_kg,
    tamano_deposito
FROM dbo.V_Depositos_Detallados
ORDER BY fecha_deposito DESC;

PRINT '';
PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- DOCUMENTACIÓN DE LA VISTA
------------------------------------------------------------
PRINT '┌────────────────────────────────────────────────────────────────┐';
PRINT '│ UTILIDAD PRÁCTICA DE LA VISTA V_Depositos_Detallados          │';
PRINT '└────────────────────────────────────────────────────────────────┘';
PRINT '';
PRINT 'Beneficios de usar esta vista:';
PRINT '';
PRINT '  1. SIMPLIFICACIÓN DE CONSULTAS:';
PRINT '     Antes: SELECT ... FROM Depositos JOIN Centros JOIN Categorias...';
PRINT '     Ahora: SELECT ... FROM V_Depositos_Detallados WHERE ...';
PRINT '';
PRINT '  2. REDUCCIÓN DE ERRORES:';
PRINT '     - Los JOINs están pre-definidos correctamente';
PRINT '     - No es posible olvidar una FK o hacer un CROSS JOIN accidental';
PRINT '';
PRINT '  3. CAMPOS CALCULADOS LISTOS:';
PRINT '     - año, mes, trimestre, dia_semana → Reportes temporales inmediatos';
PRINT '     - tamano_deposito → Segmentación automática por volumen';
PRINT '';
PRINT '  4. INTEGRACIÓN CON HERRAMIENTAS BI:';
PRINT '     - Power BI, Tableau, Excel pueden conectarse directamente';
PRINT '     - No requieren conocer la estructura interna de la BD';
PRINT '';
PRINT '  5. MANTENIBILIDAD:';
PRINT '     - Si cambia la estructura de las tablas, solo se actualiza la vista';
PRINT '     - Todas las aplicaciones siguen funcionando sin cambios';
PRINT '';

PRINT '────────────────────────────────────────────────────────────────';
PRINT '';

------------------------------------------------------------
-- EJEMPLO DE USO: Consulta simplificada con la vista
------------------------------------------------------------
PRINT '→ Ejemplo de consulta simplificada usando la vista:';
PRINT '  Pregunta de negocio: ¿Cuántos kilos de Plástico PET se recolectaron';
PRINT '  en EcoPunto Centro durante octubre 2025?';
PRINT '';

SELECT
    centro_nombre,
    categoria_nombre,
    COUNT(*) AS Cantidad_Depositos,
    CAST(SUM(cantidad_kg) AS DECIMAL(10,2)) AS Kilos_Totales
FROM dbo.V_Depositos_Detallados
WHERE 
    categoria_nombre = N'Plástico PET'
    AND centro_nombre LIKE N'%Centro%'
    AND anio = 2025
    AND mes = 10
GROUP BY centro_nombre, categoria_nombre;

PRINT '';
PRINT '  → Sin la vista, esta consulta requeriría 2 JOINs explícitos';
PRINT '  → Con la vista, es tan simple como filtrar una "tabla plana"';
PRINT '';

PRINT '████████████████████████████████████████████████████████████████';
PRINT '✓ VISTAS CREADAS Y PROBADAS EXITOSAMENTE';
PRINT '████████████████████████████████████████████████████████████████';
PRINT '';
GO

/******************************************************************************
 FIN DEL SCRIPT: 06_vistas.sql
 
 VISTA CREADA:
 - dbo.V_Depositos_Detallados
   → Consolida información de las 3 tablas principales
   → Agrega campos calculados útiles (año, mes, clasificación)
   → Simplifica consultas desde aplicaciones
   
 VENTAJAS DEMOSTRADAS:
 - Reducción de código en consultas (de 10+ líneas a 3 líneas)
 - Abstracción de la complejidad del esquema
 - Reutilización de lógica de negocio
 - Integración simplificada con herramientas BI
 
 Siguiente paso: Ejecutar 07_medicion_indices.sql para medir el impacto
 de los índices en el rendimiento de consultas.
******************************************************************************/
