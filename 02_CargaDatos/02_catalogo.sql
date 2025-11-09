/******************************************************************************
 TFI - Bases de Datos I
 Script: 02_catalogo.sql (T-SQL / SQL Server)
 
 ETAPA 2: CARGA DE DATOS MAESTROS (CATÁLOGOS)
 
 Sistema: Gestión de Reciclaje Urbano
 Autor: Mauro Ezequiel Ponce
 Fecha: Noviembre 2025
 
 Descripción:
 Este script carga los datos semilla (catálogos maestros) en las tablas de
 dimensión. Estos catálogos son prerequisito para la carga masiva de la tabla
 de hechos (RegistrosDeposito).
 
 Características:
 - Idempotente: Se puede ejecutar múltiples veces sin duplicar datos
 - Utiliza tablas temporales para inserción condicional
 - Manejo de errores con TRY/CATCH y transacciones
 
******************************************************************************/

USE [SistemaReciclajeUrbano];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '  ETAPA 2: CARGA DE CATÁLOGOS MAESTROS';
PRINT '════════════════════════════════════════════════════════════════';
PRINT '';

BEGIN TRY
    BEGIN TRANSACTION;

    ------------------------------------------------------------
    -- PASO 1: Cargar CategoriasMaterial
    ------------------------------------------------------------
    PRINT '→ Cargando CategoriasMaterial...';
    
    DECLARE @Categorias TABLE (
        nombre NVARCHAR(100) PRIMARY KEY, 
        descripcion NVARCHAR(500)
    );
    
    INSERT INTO @Categorias (nombre, descripcion) VALUES
        (N'Plástico PET',    N'Botellas y envases de tereftalato de polietileno'),
        (N'Vidrio',          N'Frascos, botellas y envases de vidrio'),
        (N'Cartón',          N'Cajas de cartón corrugado y cartulina'),
        (N'Papel',           N'Papel de oficina, periódicos y revistas'),
        (N'Aluminio',        N'Latas de aluminio y envases metálicos');

    -- Inserción idempotente (solo si no existen)
    INSERT INTO dbo.CategoriasMaterial (nombre, descripcion)
    SELECT c.nombre, c.descripcion
    FROM @Categorias c
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.CategoriasMaterial cm
        WHERE cm.nombre = c.nombre
    );
    
    DECLARE @catInsertadas INT = @@ROWCOUNT;
    PRINT '  ✓ Categorías procesadas: ' + CAST(@catInsertadas AS NVARCHAR(10)) + ' insertadas';
    
    ------------------------------------------------------------
    -- PASO 2: Cargar CentrosAcopio
    ------------------------------------------------------------
    PRINT '';
    PRINT '→ Cargando CentrosAcopio...';
    
    DECLARE @Centros TABLE (
        nombre NVARCHAR(200) PRIMARY KEY, 
        direccion NVARCHAR(300),
        codigo_postal NVARCHAR(10),
        horario NVARCHAR(150),
        capacidad_kg DECIMAL(10,2),
        fecha_apertura DATE
    );
    
    INSERT INTO @Centros (nombre, direccion, codigo_postal, horario, capacidad_kg, fecha_apertura) VALUES
        (N'EcoPunto Centro',     N'Av. Rivadavia 5000, CABA',      N'C1424',  N'Lun-Vie 8:00-18:00',  5000.00, '2023-01-15'),
        (N'EcoPunto Palermo',    N'Av. Santa Fe 3500, CABA',       N'C1425',  N'Lun-Sáb 9:00-20:00',  8000.00, '2023-03-10'),
        (N'EcoPunto Belgrano',   N'Av. Cabildo 2100, CABA',        N'C1428',  N'Mar-Dom 10:00-18:00', 6000.00, '2023-05-20'),
        (N'EcoPunto Villa Urquiza', N'Av. Triunvirato 4500, CABA', N'C1431',  N'Lun-Vie 7:00-19:00',  7000.00, '2023-07-01');

    -- Inserción idempotente
    INSERT INTO dbo.CentrosAcopio (nombre, direccion, codigo_postal, horario, capacidad_kg, fecha_apertura)
    SELECT ce.nombre, ce.direccion, ce.codigo_postal, ce.horario, ce.capacidad_kg, ce.fecha_apertura
    FROM @Centros ce
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.CentrosAcopio ca
        WHERE ca.nombre = ce.nombre
    );
    
    DECLARE @centInsertados INT = @@ROWCOUNT;
    PRINT '  ✓ Centros procesados: ' + CAST(@centInsertados AS NVARCHAR(10)) + ' insertados';

    COMMIT TRANSACTION;
    
    ------------------------------------------------------------
    -- RESUMEN FINAL
    ------------------------------------------------------------
    PRINT '';
    PRINT '════════════════════════════════════════════════════════════════';
    PRINT '  RESUMEN DE CARGA:';
    
    -- CORRECCIÓN PARA Msg 1046:
    -- No se pueden usar subconsultas (SELECT...) directamente en un PRINT.
    -- Primero, guardamos los valores en variables escalares.
    DECLARE @TotalCategorias INT, @TotalCentros INT;
    SELECT @TotalCategorias = COUNT(*) FROM dbo.CategoriasMaterial;
    SELECT @TotalCentros = COUNT(*) FROM dbo.CentrosAcopio;
    
    -- Ahora usamos las variables en el PRINT.
    PRINT '  - Categorías de Material: ' + CAST(@TotalCategorias AS NVARCHAR(10)) + ' totales';
    PRINT '  - Centros de Acopio: ' + CAST(@TotalCentros AS NVARCHAR(10)) + ' totales';
    
    PRINT '════════════════════════════════════════════════════════════════';
    PRINT '✓ CATÁLOGOS CARGADOS EXITOSAMENTE';
    PRINT '';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    
    PRINT '';
    PRINT '✗ ERROR EN CARGA DE CATÁLOGOS:';
    PRINT '  Mensaje: ' + @ErrMsg;
    PRINT '  Gravedad: ' + CAST(@ErrSev AS NVARCHAR(10));
    PRINT '';
    
    RAISERROR('Error en 02_catalogo.sql: %s', @ErrSev, @ErrState, @ErrMsg);
END CATCH;
GO

/******************************************************************************
 FIN DEL SCRIPT: 02_catalogo.sql
 
 Siguiente paso: Ejecutar 03_carga_masiva.sql para generar el volumen de
 datos transaccionales necesario para las pruebas de consultas y rendimiento.
******************************************************************************/
