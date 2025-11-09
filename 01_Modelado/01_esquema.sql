/******************************************************************************
 TFI - Bases de Datos I
 Script: 01_esquema.sql (T-SQL / SQL Server)
 
 ETAPA 1: MODELADO Y DEFINICIÓN DE CONSTRAINTS
 
 Sistema: Gestión de Reciclaje Urbano
 Autor: Mauro Ezequiel Ponce
 Fecha: Noviembre 2025
 
 Descripción:
 Este script crea la estructura fundacional de la base de datos, implementando
 todas las restricciones de integridad necesarias para garantizar la calidad
 de los datos a nivel de motor.
 
 Entidades del Dominio:
 - CentrosAcopio: Puntos de recolección de materiales reciclables
 - CategoriasMaterial: Tipos de materiales aceptados (PET, Vidrio, Cartón, etc.)
 - RegistrosDeposito: Transacciones de depósito (tabla de hechos)
 
******************************************************************************/

SET NOCOUNT ON;
GO

------------------------------------------------------------
-- SECCIÓN 1: CREACIÓN DE LA BASE DE DATOS
------------------------------------------------------------
PRINT '========================================';
PRINT 'ETAPA 1: CREACIÓN DE BASE DE DATOS';
PRINT '========================================';
PRINT '';

DECLARE @db_name SYSNAME = N'SistemaReciclajeUrbano';
DECLARE @sql NVARCHAR(MAX);

-- Verificar si la BD ya existe
IF DB_ID(@db_name) IS NOT NULL
BEGIN
    PRINT '⚠ La base de datos ya existe. Se eliminará y recreará.';
    
    -- Forzar cierre de conexiones activas
    SET @sql = N'ALTER DATABASE [' + @db_name + N'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
    EXEC (@sql);
    
    -- Eliminar BD
    SET @sql = N'DROP DATABASE [' + @db_name + N'];';
    EXEC (@sql);
    
    PRINT '✓ Base de datos anterior eliminada.';
END

-- Crear nueva BD
SET @sql = N'CREATE DATABASE [' + @db_name + N'];';
EXEC (@sql);

PRINT '✓ Base de datos "' + @db_name + '" creada exitosamente.';
PRINT '';
GO

-- Seleccionar la BD para trabajar
USE [SistemaReciclajeUrbano];
GO

------------------------------------------------------------
-- SECCIÓN 2: CREACIÓN DE TABLAS CON CONSTRAINTS
------------------------------------------------------------
PRINT '========================================';
PRINT 'SECCIÓN 2: CREACIÓN DE TABLAS';
PRINT '========================================';
PRINT '';

------------------------------------------------------------
-- TABLA 1: CategoriasMaterial (Dimensión)
------------------------------------------------------------
PRINT '→ Creando tabla: CategoriasMaterial';

CREATE TABLE dbo.CategoriasMaterial
(
    id_categoria    INT IDENTITY(1,1) NOT NULL,
    nombre          NVARCHAR(100) NOT NULL,
    descripcion     NVARCHAR(500) NULL,
    activo          BIT NOT NULL DEFAULT 1,
    fecha_creacion  DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    
    -- CONSTRAINT: Primary Key (R-PK-01)
    -- Garantiza que cada categoría tenga un identificador único e inmutable
    CONSTRAINT PK_CategoriasMaterial PRIMARY KEY CLUSTERED (id_categoria),
    
    -- CONSTRAINT: Unique (R-UQ-01)
    -- Evita la duplicación de nombres de categorías en el catálogo maestro
    CONSTRAINT UQ_CategoriasMaterial_Nombre UNIQUE (nombre)
);

PRINT '  ✓ Tabla CategoriasMaterial creada';
PRINT '    - PK: id_categoria (IDENTITY)';
PRINT '    - UNIQUE: nombre';
PRINT '';
GO

------------------------------------------------------------
-- TABLA 2: CentrosAcopio (Dimensión)
------------------------------------------------------------
PRINT '→ Creando tabla: CentrosAcopio';

CREATE TABLE dbo.CentrosAcopio
(
    id_centro       INT IDENTITY(1,1) NOT NULL,
    nombre          NVARCHAR(200) NOT NULL,
    direccion       NVARCHAR(300) NOT NULL,
    codigo_postal   NVARCHAR(10) NULL,
    horario         NVARCHAR(150) NULL,
    capacidad_kg    DECIMAL(10,2) NULL,
    activo          BIT NOT NULL DEFAULT 1,
    fecha_apertura  DATE NULL,
    
    -- CONSTRAINT: Primary Key (R-PK-02)
    CONSTRAINT PK_CentrosAcopio PRIMARY KEY CLUSTERED (id_centro),
    
    -- CONSTRAINT: Unique (R-UQ-02)
    -- Un centro de acopio no puede tener el mismo nombre que otro
    CONSTRAINT UQ_CentrosAcopio_Nombre UNIQUE (nombre),
    
    -- CONSTRAINT: Check (R-CHK-01)
    -- La capacidad, si se especifica, debe ser positiva
    CONSTRAINT CHK_CentrosAcopio_Capacidad CHECK (capacidad_kg IS NULL OR capacidad_kg > 0)
);

PRINT '  ✓ Tabla CentrosAcopio creada';
PRINT '    - PK: id_centro (IDENTITY)';
PRINT '    - UNIQUE: nombre';
PRINT '    - CHECK: capacidad_kg > 0 (si no es NULL)';
PRINT '';
GO

------------------------------------------------------------
-- TABLA 3: RegistrosDeposito (Tabla de Hechos)
------------------------------------------------------------
PRINT '→ Creando tabla: RegistrosDeposito';

CREATE TABLE dbo.RegistrosDeposito
(
    id_registro         INT IDENTITY(1,1) NOT NULL,
    id_centro_fk        INT NOT NULL,
    id_categoria_fk     INT NOT NULL,
    cantidad_kg         DECIMAL(10,2) NOT NULL,
    fecha_deposito      DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    observaciones       NVARCHAR(500) NULL,
    
    -- CONSTRAINT: Primary Key (R-PK-03)
    CONSTRAINT PK_RegistrosDeposito PRIMARY KEY CLUSTERED (id_registro),
    
    -- CONSTRAINT: Foreign Key hacia CentrosAcopio (R-FK-01)
    -- Garantiza que todo registro esté asociado a un centro válido (no huérfano)
    CONSTRAINT FK_Registro_Centro 
        FOREIGN KEY (id_centro_fk) 
        REFERENCES dbo.CentrosAcopio(id_centro)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    
    -- CONSTRAINT: Foreign Key hacia CategoriasMaterial (R-FK-02)
    -- Garantiza que todo registro esté asociado a una categoría válida
    CONSTRAINT FK_Registro_Categoria 
        FOREIGN KEY (id_categoria_fk) 
        REFERENCES dbo.CategoriasMaterial(id_categoria)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    
    -- CONSTRAINT: Check (R-CHK-02)
    -- La cantidad depositada debe ser estrictamente positiva (no se aceptan 0 ni negativos)
    CONSTRAINT CHK_Registro_CantidadPositiva CHECK (cantidad_kg > 0),
    
    -- CONSTRAINT: Check (R-CHK-03)
    -- La fecha de depósito no puede ser futura
    CONSTRAINT CHK_Registro_FechaNoFutura CHECK (fecha_deposito <= SYSDATETIME())
);

PRINT '  ✓ Tabla RegistrosDeposito creada';
PRINT '    - PK: id_registro (IDENTITY)';
PRINT '    - FK: id_centro_fk → CentrosAcopio';
PRINT '    - FK: id_categoria_fk → CategoriasMaterial';
PRINT '    - CHECK: cantidad_kg > 0';
PRINT '    - CHECK: fecha_deposito <= HOY';
PRINT '';
GO

------------------------------------------------------------
-- SECCIÓN 3: ÍNDICES DE RENDIMIENTO
------------------------------------------------------------
PRINT '========================================';
PRINT 'SECCIÓN 3: CREACIÓN DE ÍNDICES';
PRINT '========================================';
PRINT '';

-- Índice para acelerar JOINs por centro
CREATE NONCLUSTERED INDEX IX_RegistrosDeposito_Centro
    ON dbo.RegistrosDeposito(id_centro_fk)
    INCLUDE (cantidad_kg, fecha_deposito);

PRINT '  ✓ Índice creado: IX_RegistrosDeposito_Centro';

-- Índice para acelerar JOINs por categoría
CREATE NONCLUSTERED INDEX IX_RegistrosDeposito_Categoria
    ON dbo.RegistrosDeposito(id_categoria_fk)
    INCLUDE (cantidad_kg, fecha_deposito);

PRINT '  ✓ Índice creado: IX_RegistrosDeposito_Categoria';

-- Índice para consultas por rango de fechas
CREATE NONCLUSTERED INDEX IX_RegistrosDeposito_Fecha
    ON dbo.RegistrosDeposito(fecha_deposito)
    INCLUDE (id_centro_fk, id_categoria_fk, cantidad_kg);

PRINT '  ✓ Índice creado: IX_RegistrosDeposito_Fecha';
PRINT '';
GO

------------------------------------------------------------
-- SECCIÓN 4: DATOS SEMILLA (CATÁLOGOS MAESTROS)
------------------------------------------------------------
PRINT '========================================';
PRINT 'SECCIÓN 4: CARGA DE DATOS SEMILLA';
PRINT '========================================';
PRINT '';

-- Insertar categorías de materiales
INSERT INTO dbo.CategoriasMaterial (nombre, descripcion) VALUES
(N'Plástico PET',    N'Botellas y envases de tereftalato de polietileno'),
(N'Vidrio',          N'Frascos, botellas y envases de vidrio'),
(N'Cartón',          N'Cajas de cartón corrugado y cartulina'),
(N'Papel',           N'Papel de oficina, periódicos y revistas'),
(N'Aluminio',        N'Latas de aluminio y envases metálicos');

PRINT '  ✓ Insertadas 5 categorías de materiales';

-- Insertar centros de acopio
INSERT INTO dbo.CentrosAcopio (nombre, direccion, codigo_postal, horario, capacidad_kg, fecha_apertura) VALUES
(N'EcoPunto Centro',     N'Av. Rivadavia 5000, CABA',      N'C1424',  N'Lun-Vie 8:00-18:00',  5000.00, '2023-01-15'),
(N'EcoPunto Palermo',    N'Av. Santa Fe 3500, CABA',       N'C1425',  N'Lun-Sáb 9:00-20:00',  8000.00, '2023-03-10'),
(N'EcoPunto Belgrano',   N'Av. Cabildo 2100, CABA',        N'C1428',  N'Mar-Dom 10:00-18:00', 6000.00, '2023-05-20'),
(N'EcoPunto Villa Urquiza', N'Av. Triunvirato 4500, CABA', N'C1431',  N'Lun-Vie 7:00-19:00',  7000.00, '2023-07-01');

PRINT '  ✓ Insertados 4 centros de acopio';
PRINT '';

-- Insertar algunos registros de ejemplo
INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg, fecha_deposito) VALUES
(1, 1, 15.50, '2024-10-01 10:30:00'),
(1, 2, 22.00, '2024-10-01 11:15:00'),
(2, 1, 18.75, '2024-10-02 09:45:00'),
(2, 3, 45.20, '2024-10-02 14:20:00'),
(3, 4, 12.80, '2024-10-03 08:10:00'),
(3, 5,  9.50, '2024-10-03 16:30:00'),
(4, 2, 28.90, '2024-10-04 11:00:00'),
(4, 3, 35.40, '2024-10-04 15:45:00');

PRINT '  ✓ Insertados 8 registros de depósito de ejemplo';
PRINT '';
GO

------------------------------------------------------------
-- SECCIÓN 5: VERIFICACIÓN DE LA ESTRUCTURA
------------------------------------------------------------
PRINT '========================================';
PRINT 'SECCIÓN 5: VERIFICACIÓN FINAL';
PRINT '========================================';
PRINT '';

-- Contar registros por tabla
DECLARE @count_categorias INT, @count_centros INT, @count_registros INT;

SELECT @count_categorias = COUNT(*) FROM dbo.CategoriasMaterial;
SELECT @count_centros = COUNT(*) FROM dbo.CentrosAcopio;
SELECT @count_registros = COUNT(*) FROM dbo.RegistrosDeposito;

PRINT '  Registros en CategoriasMaterial: ' + CAST(@count_categorias AS NVARCHAR(10));
PRINT '  Registros en CentrosAcopio: ' + CAST(@count_centros AS NVARCHAR(10));
PRINT '  Registros en RegistrosDeposito: ' + CAST(@count_registros AS NVARCHAR(10));
PRINT '';

-- Listar constraints creadas
PRINT '  Constraints de Integridad:';
SELECT 
    OBJECT_NAME(parent_object_id) AS Tabla,
    name AS Constraint_Nombre,
    type_desc AS Tipo
FROM sys.objects
WHERE type_desc LIKE '%CONSTRAINT%'
  AND OBJECT_NAME(parent_object_id) IN ('CategoriasMaterial', 'CentrosAcopio', 'RegistrosDeposito')
ORDER BY Tabla, Tipo;

PRINT '';
PRINT '========================================';
PRINT '✓ ETAPA 1 COMPLETADA EXITOSAMENTE';
PRINT '========================================';
GO

/******************************************************************************
 FIN DEL SCRIPT
 
 -Siguiente paso: Ejecutar 01b_validacion_constraints.sql para validar
 que todas las restricciones de integridad funcionan correctamente.
******************************************************************************/
