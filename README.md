# 🌱 Sistema de Gestión de Reciclaje Urbano

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019+-CC2927?style=flat&logo=microsoft-sql-server)](https://www.microsoft.com/sql-server)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/TU_USUARIO/SistemaReciclajeUrbano?style=social)](https://github.com/TU_USUARIO/SistemaReciclajeUrbano)

> **Trabajo Final Integrador** - Bases de Datos I  
> Sistema completo de gestión de centros de acopio y materiales reciclables con 10,000+ registros de prueba.
> LINK A TODOS LOS ARCHIVOS EN DRIVE: https://drive.google.com/drive/folders/1HHgTrd_808dowNQoGdHTwLFXogmgcuS8?usp=sharing
---

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Características](#-características)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos](#-requisitos)
- [Instalación](#-instalación)
- [Uso](#-uso)
- [Modelo de Datos](#-modelo-de-datos)
- [Consultas Destacadas](#-consultas-destacadas)
- [Seguridad](#-seguridad)
- [Autor](#-autor)

---

## 🎯 Descripción

Sistema de base de datos relacional para la gestión de reciclaje urbano que permite:

- Administrar **centros de acopio** con ubicación y capacidad
- Catalogar **categorías de materiales** reciclables (PET, Vidrio, Cartón, etc.)
- Registrar **depósitos** con trazabilidad completa
- Generar **reportes analíticos** para toma de decisiones
- Implementar **medidas de seguridad** contra SQL Injection

---

## ✨ Características

### 🗄️ Base de Datos
- **Modelo relacional normalizado** (3FN)
- **Constraints de integridad**: PK, FK, UNIQUE, CHECK
- **Índices optimizados** para consultas frecuentes
- **10,000 registros** de prueba generados automáticamente

### 📊 Consultas Avanzadas
- JOINs múltiples con agregación
- GROUP BY + HAVING para alertas
- Subconsultas con CTEs y ROW_NUMBER
- Vistas para simplificar acceso a datos

### 🔒 Seguridad
- Usuario con **privilegios mínimos**
- **Vistas seguras** que ocultan información sensible
- **Procedimientos almacenados** anti-SQL Injection
- Validación de **integridad referencial**

### ⚡ Concurrencia
- Simulación de **deadlocks**
- Comparación de **niveles de aislamiento**
- Transacciones con **retry automático**

---

## 📁 Estructura del Proyecto

```
SistemaReciclajeUrbano/
│
├── 01_Modelado/               # Creación del esquema
│   ├── 01_esquema.sql
│   └── 01b_validacion_constraints.sql
│
├── 02_CargaDatos/             # Población de datos
│   ├── 02_catalogo.sql
│   ├── 03_carga_masiva.sql
│   └── 04_verificaciones.sql
│
├── 03_Consultas/              # Reportes y análisis
│   ├── 05_consultas_avanzadas.sql
│   ├── 06_vistas.sql
│   └── 07_medicion_indices.sql
│
├── 04_Seguridad/              # Medidas de seguridad
│   ├── 09_Seguridad.sql
│   └── RegistroDepositoSeguro.java
│
└── 05_Concurrencia/           # Transacciones concurrentes
    ├── 10_Concurrencia.sql
    ├── Session1.sql
    └── Session2.sql
```

---

## 🛠️ Requisitos

- **SQL Server 2019** o superior
- **SQL Server Management Studio (SSMS)** 18.0+
- **Java JDK 11+** (opcional, para pruebas anti-inyección)
- Permisos de **sysadmin** en SQL Server

---

## 🚀 Instalación

### Paso 1: Clonar el repositorio
```bash
git clone https://github.com/TU_USUARIO/SistemaReciclajeUrbano.git
cd SistemaReciclajeUrbano
```

### Paso 2: Ejecutar scripts en orden
```sql
-- En SQL Server Management Studio, ejecutar en este orden:

-- 1. Crear esquema
:r 01_Modelado\01_esquema.sql

-- 2. Cargar catálogos
:r 02_CargaDatos\02_catalogo.sql

-- 3. Generar datos masivos (10,000 registros)
:r 02_CargaDatos\03_carga_masiva.sql

-- 4. Verificar integridad
:r 02_CargaDatos\04_verificaciones.sql
```

### Paso 3: Verificar instalación
```sql
USE SistemaReciclajeUrbano;

-- Verificar conteo de registros
SELECT 
    (SELECT COUNT(*) FROM CategoriasMaterial) AS Categorias,
    (SELECT COUNT(*) FROM CentrosAcopio) AS Centros,
    (SELECT COUNT(*) FROM RegistrosDeposito) AS Depositos;
```

**Resultado esperado:**
```
Categorias  Centros  Depositos
5           4        10000
```

---

## 💻 Uso

### Consultas básicas

```sql
-- Ranking de materiales más reciclados
SELECT TOP 5
    cm.nombre AS Material,
    COUNT(rd.id_registro) AS Depositos,
    SUM(rd.cantidad_kg) AS Kilos_Totales
FROM RegistrosDeposito rd
INNER JOIN CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
GROUP BY cm.nombre
ORDER BY Kilos_Totales DESC;
```

### Usando vistas

```sql
-- Ver depósitos con información completa
SELECT TOP 10 *
FROM V_Depositos_Detallados
WHERE categoria_nombre = 'Plástico PET'
ORDER BY fecha_deposito DESC;
```

### Procedimiento seguro

```sql
-- Registrar depósito de forma segura
EXEC sp_RegistrarDepositoSeguro
    @nombre_centro = 'EcoPunto Centro',
    @nombre_material = 'Papel',
    @cantidad_kg = 15.50;
```

---

## 📐 Modelo de Datos

### Diagrama Entidad-Relación

```
┌─────────────────────┐
│ CategoriasMaterial  │
├─────────────────────┤
│ PK id_categoria     │
│    nombre (UQ)      │
│    descripcion      │
│    activo           │
└──────────┬──────────┘
           │ 1
           │
           │ N
┌──────────┴──────────┐         ┌─────────────────┐
│ RegistrosDeposito   │         │  CentrosAcopio  │
├─────────────────────┤         ├─────────────────┤
│ PK id_registro      │    N    │ PK id_centro    │
│ FK id_centro_fk     ├─────────┤    nombre (UQ)  │
│ FK id_categoria_fk  │    1    │    direccion    │
│    cantidad_kg (>0) │         │    horario      │
│    fecha_deposito   │         │    capacidad_kg │
└─────────────────────┘         └─────────────────┘
```

### Reglas de negocio implementadas

| Constraint | Tabla | Descripción |
|------------|-------|-------------|
| PK_CategoriasMaterial | CategoriasMaterial | Identificador único |
| UQ_CategoriasMaterial_Nombre | CategoriasMaterial | Nombre único |
| PK_CentrosAcopio | CentrosAcopio | Identificador único |
| UQ_CentrosAcopio_Nombre | CentrosAcopio | Nombre único |
| CHK_CentrosAcopio_Capacidad | CentrosAcopio | Capacidad > 0 |
| FK_Registro_Centro | RegistrosDeposito | Centro debe existir |
| FK_Registro_Categoria | RegistrosDeposito | Categoría debe existir |
| CHK_Registro_CantidadPositiva | RegistrosDeposito | Cantidad > 0 |
| CHK_Registro_FechaNoFutura | RegistrosDeposito | Fecha <= HOY |

---

## 🔍 Consultas Destacadas

### 1. Alertas de centros con baja actividad

```sql
-- Centros con menos de 100 depósitos en 30 días
SELECT
    ca.nombre AS Centro_Alerta,
    COUNT(rd.id_registro) AS Depositos_Ultimos_30d
FROM CentrosAcopio ca
LEFT JOIN RegistrosDeposito rd ON ca.id_centro = rd.id_centro_fk
    AND rd.fecha_deposito >= DATEADD(DAY, -30, GETDATE())
WHERE ca.activo = 1
GROUP BY ca.nombre
HAVING COUNT(rd.id_registro) < 100
ORDER BY Depositos_Ultimos_30d ASC;
```

### 2. Último depósito por centro

```sql
-- Usando CTE con ROW_NUMBER
WITH UltimosDepositos AS (
    SELECT
        ca.nombre AS Centro,
        rd.fecha_deposito,
        cm.nombre AS Material,
        ROW_NUMBER() OVER (PARTITION BY rd.id_centro_fk ORDER BY rd.fecha_deposito DESC) AS rn
    FROM RegistrosDeposito rd
    INNER JOIN CentrosAcopio ca ON rd.id_centro_fk = ca.id_centro
    INNER JOIN CategoriasMaterial cm ON rd.id_categoria_fk = cm.id_categoria
)
SELECT Centro, Material, fecha_deposito AS Ultimo_Deposito
FROM UltimosDepositos
WHERE rn = 1;
```

---

## 🔒 Seguridad

### Protección contra SQL Injection

#### ❌ Código VULNERABLE (NO usar)
```sql
-- Concatenación directa = PELIGROSO
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Centros WHERE nombre = ''' + @input + '''';
EXEC(@sql);
```

#### ✅ Código SEGURO (implementado)
```sql
-- Parámetros con sp_executesql = SEGURO
DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM Centros WHERE nombre = @nombre';
EXEC sp_executesql @sql, N'@nombre NVARCHAR(100)', @nombre = @input;
```

### Java con PreparedStatement

```java
// ✅ SEGURO: Los valores nunca se concatenan
String sql = "SELECT id_centro FROM CentrosAcopio WHERE nombre = ?";
PreparedStatement ps = conn.prepareStatement(sql);
ps.setString(1, nombreCentro); // Escapado automáticamente
ResultSet rs = ps.executeQuery();
```

---

## 📊 Estadísticas del Proyecto

| Métrica | Valor |
|---------|-------|
| Scripts SQL | 13 |
| Líneas de código | ~2,500 |
| Tablas | 3 |
| Vistas | 2 |
| Procedimientos almacenados | 2 |
| Constraints | 9 |
| Índices | 3 |
| Registros de prueba | 10,000 |

---

## 🤝 Contribuciones

Este es un proyecto académico, pero las sugerencias son bienvenidas:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -m 'Add: nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

---

## 👨‍💻 Autor

**Mauro Ezequiel Ponce**

- 📧 Email: mauroezequielp11@gmail.com
- 🎓 Universidad: UNIVERSIDAD TECNOLOGICA NACIONAL
- 📅 Fecha: Noviembre 2025

---

## 📚 Referencias

- [SQL Server Documentation](https://docs.microsoft.com/sql)
- [T-SQL Best Practices](https://www.sqlshack.com/t-sql-best-practices/)
- [Database Normalization](https://www.guru99.com/database-normalization.html)

---

<div align="center">


[![GitHub stars](https://img.shields.io/github/stars/TU_USUARIO/SistemaReciclajeUrbano?style=social)](https://github.com/TU_USUARIO/SistemaReciclajeUrbano/stargazers)

</div>
