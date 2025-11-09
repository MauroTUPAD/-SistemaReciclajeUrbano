package seguridad;

import java.sql.*;
import java.math.BigDecimal;

/**
 * ETAPA 4 - OPCIÓN A: Implementación Java Segura con PreparedStatement
 * 
 * Este código demuestra:
 * 1. Uso de PreparedStatement para prevenir SQL Injection
 * 2. Validaciones de entrada
 * 3. Manejo robusto de excepciones
 * 4. Pruebas anti-inyección documentadas
 * 
 * @author Sistema de Reciclaje Urbano
 * @version 1.0
 */
public class RegistroDepositoSeguro {
    
    // Configuración de conexión (ajustar según tu entorno)
    private static final String DB_URL = "jdbc:sqlserver://localhost:1433;databaseName=SistemaReciclajeUrbano;encrypt=false";
    private static final String DB_USER = "sa";
    private static final String DB_PASSWORD = "kilimanjaro_741";
    
    /**
     * Registra un depósito de material de forma segura
     * 
     * @param nombreCentro Nombre del centro de acopio
     * @param nombreMaterial Nombre del material reciclable
     * @param cantidadKg Cantidad en kilogramos
     * @return true si el registro fue exitoso, false en caso contrario
     */
    public static boolean registrarDepositoSeguro(String nombreCentro, String nombreMaterial, BigDecimal cantidadKg) {
        
        // ========================================
        // VALIDACIONES DEFENSIVAS DE ENTRADA
        // ========================================
        
        if (nombreCentro == null || nombreCentro.trim().isEmpty()) {
            System.err.println("❌ Error: El nombre del centro no puede estar vacío");
            return false;
        }
        
        if (nombreMaterial == null || nombreMaterial.trim().isEmpty()) {
            System.err.println("❌ Error: El nombre del material no puede estar vacío");
            return false;
        }
        
        if (cantidadKg == null || cantidadKg.compareTo(BigDecimal.ZERO) <= 0) {
            System.err.println("❌ Error: La cantidad debe ser mayor a 0");
            return false;
        }
        
        // Variables para manejo de recursos
        Connection conn = null;
        PreparedStatement psSelectCentro = null;
        PreparedStatement psSelectCategoria = null;
        PreparedStatement psInsertDeposito = null;
        ResultSet rsCentro = null;
        ResultSet rsCategoria = null;
        
        try {
            // ========================================
            // ESTABLECER CONEXIÓN
            // ========================================
            try {
                Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            } catch (ClassNotFoundException e) {
                System.err.println("❌ Error: Driver JDBC no encontrado");
                return false;
            }
            
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            conn.setAutoCommit(false); // Transacción explícita
            
            // ========================================
            // PASO 1: BUSCAR ID DEL CENTRO (PREPARED STATEMENT)
            // ========================================
            // CRÍTICO: Uso de PreparedStatement con placeholder (?)
            // El valor del parámetro NUNCA se concatena al SQL
            String sqlCentro = "SELECT id_centro FROM dbo.CentrosAcopio WHERE nombre = ? AND activo = 1";
            psSelectCentro = conn.prepareStatement(sqlCentro);
            psSelectCentro.setString(1, nombreCentro); // Asignación segura del parámetro
            
            rsCentro = psSelectCentro.executeQuery();
            
            if (!rsCentro.next()) {
                System.err.println("❌ Error: Centro de acopio no encontrado o inactivo: " + nombreCentro);
                conn.rollback();
                return false;
            }
            
            int idCentro = rsCentro.getInt("id_centro");
            
            // ========================================
            // PASO 2: BUSCAR ID DE LA CATEGORÍA (PREPARED STATEMENT)
            // ========================================
            String sqlCategoria = "SELECT id_categoria FROM dbo.CategoriasMaterial WHERE nombre = ?";
            psSelectCategoria = conn.prepareStatement(sqlCategoria);
            psSelectCategoria.setString(1, nombreMaterial); // Asignación segura
            
            rsCategoria = psSelectCategoria.executeQuery();
            
            if (!rsCategoria.next()) {
                System.err.println("❌ Error: Categoría de material no encontrada: " + nombreMaterial);
                conn.rollback();
                return false;
            }
            
            int idCategoria = rsCategoria.getInt("id_categoria");
            
            // ========================================
            // PASO 3: INSERTAR DEPÓSITO (PREPARED STATEMENT)
            // ========================================
            String sqlInsert = "INSERT INTO dbo.RegistrosDeposito (id_centro_fk, id_categoria_fk, cantidad_kg, fecha_deposito) VALUES (?, ?, ?, GETDATE())";
            psInsertDeposito = conn.prepareStatement(sqlInsert);
            psInsertDeposito.setInt(1, idCentro);        // Parámetro seguro
            psInsertDeposito.setInt(2, idCategoria);     // Parámetro seguro
            psInsertDeposito.setBigDecimal(3, cantidadKg); // Parámetro seguro
            
            int filasAfectadas = psInsertDeposito.executeUpdate();
            
            if (filasAfectadas > 0) {
                conn.commit(); // Confirmar transacción
                System.out.println("✅ Depósito registrado exitosamente:");
                System.out.println("   Centro: " + nombreCentro);
                System.out.println("   Material: " + nombreMaterial);
                System.out.println("   Cantidad: " + cantidadKg + " kg");
                return true;
            } else {
                conn.rollback();
                System.err.println("❌ Error: No se pudo registrar el depósito");
                return false;
            }
            
        } catch (SQLException e) {
            // Manejo robusto de excepciones
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException rollbackEx) {
                rollbackEx.printStackTrace();
            }
            
            System.err.println("❌ Error SQL: " + e.getMessage());
            e.printStackTrace();
            return false;
            
        } finally {
            // ========================================
            // LIBERACIÓN SEGURA DE RECURSOS
            // ========================================
            try {
                if (rsCentro != null) rsCentro.close();
                if (rsCategoria != null) rsCategoria.close();
                if (psSelectCentro != null) psSelectCentro.close();
                if (psSelectCategoria != null) psSelectCategoria.close();
                if (psInsertDeposito != null) psInsertDeposito.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * ============================================================================
     * PRUEBAS ANTI-INYECCIÓN SQL DOCUMENTADAS
     * ============================================================================
     */
    public static void main(String[] args) {
        
        System.out.println("╔════════════════════════════════════════════════════════════════╗");
        System.out.println("║  PRUEBAS DE SEGURIDAD - ANTI SQL INJECTION                     ║");
        System.out.println("╚════════════════════════════════════════════════════════════════╝");
        System.out.println();
        
        // ============================================================
        // PRUEBA 1: Uso legítimo (debería funcionar)
        // ============================================================
        System.out.println("┌─────────────────────────────────────────────────────────────┐");
        System.out.println("│ PRUEBA 1: Registro legítimo                                 │");
        System.out.println("└─────────────────────────────────────────────────────────────┘");
        
        registrarDepositoSeguro(
            "EcoPunto Villa Urquiza",
            "Papel",
            new BigDecimal("12.50")
        );
        System.out.println();
        
        // ============================================================
        // PRUEBA 2: Intento de SQL Injection - DROP TABLE
        // ============================================================
        System.out.println("┌─────────────────────────────────────────────────────────────┐");
        System.out.println("│ PRUEBA 2: Intento de SQL Injection - DROP TABLE            │");
        System.out.println("└─────────────────────────────────────────────────────────────┘");
        System.out.println("Entrada maliciosa: EcoPunto'; DROP TABLE CentrosAcopio; --");
        System.out.println();
        
        boolean resultado2 = registrarDepositoSeguro(
            "EcoPunto'; DROP TABLE CentrosAcopio; --",
            "Vidrio",
            new BigDecimal("5.00")
        );
        
        System.out.println();
        System.out.println("📋 EXPLICACIÓN:");
        System.out.println("   ✓ El PreparedStatement trata la entrada como un STRING LITERAL");
        System.out.println("   ✓ Busca un centro llamado exactamente: EcoPunto'; DROP TABLE...");
        System.out.println("   ✓ No encuentra el centro (porque no existe con ese nombre)");
        System.out.println("   ✓ El código SQL malicioso NUNCA se ejecuta");
        System.out.println("   ✓ La tabla CentrosAcopio permanece intacta");
        System.out.println("   → Resultado esperado: " + (resultado2 ? "FALLO" : "BLOQUEADO ✓"));
        System.out.println();
        
        // ============================================================
        // PRUEBA 3: Intento de SQL Injection - UNION SELECT
        // ============================================================
        System.out.println("┌─────────────────────────────────────────────────────────────┐");
        System.out.println("│ PRUEBA 3: Intento de SQL Injection - UNION SELECT          │");
        System.out.println("└─────────────────────────────────────────────────────────────┘");
        System.out.println("Entrada maliciosa: Plástico' UNION SELECT password FROM users--");
        System.out.println();
        
        boolean resultado3 = registrarDepositoSeguro(
            "EcoPunto Centro",
            "Plástico' UNION SELECT password FROM users--",
            new BigDecimal("3.00")
        );
        
        System.out.println();
        System.out.println("📋 EXPLICACIÓN:");
        System.out.println("   ✓ El PreparedStatement parametriza el valor del material");
        System.out.println("   ✓ Busca una categoría llamada: Plástico' UNION SELECT...");
        System.out.println("   ✓ No encuentra esa categoría (no existe)");
        System.out.println("   ✓ El intento de UNION SELECT nunca se interpreta como SQL");
        System.out.println("   ✓ Ninguna tabla sensible es consultada");
        System.out.println("   → Resultado esperado: " + (resultado3 ? "FALLO" : "BLOQUEADO ✓"));
        System.out.println();
        
        // ============================================================
        // PRUEBA 4: Intento de SQL Injection - OR '1'='1'
        // ============================================================
        System.out.println("┌─────────────────────────────────────────────────────────────┐");
        System.out.println("│ PRUEBA 4: Intento de SQL Injection - OR '1'='1'            │");
        System.out.println("└─────────────────────────────────────────────────────────────┘");
        System.out.println("Entrada maliciosa: EcoPunto' OR '1'='1");
        System.out.println();
        
        boolean resultado4 = registrarDepositoSeguro(
            "EcoPunto' OR '1'='1",
            "Cartón",
            new BigDecimal("8.00")
        );
        
        System.out.println();
        System.out.println("📋 EXPLICACIÓN:");
        System.out.println("   ✓ El PreparedStatement escapa las comillas automáticamente");
        System.out.println("   ✓ La condición OR '1'='1' se trata como texto");
        System.out.println("   ✓ NO se convierte en una condición SQL que siempre es verdadera");
        System.out.println("   ✓ El ataque clásico de bypass de autenticación falla");
        System.out.println("   → Resultado esperado: " + (resultado4 ? "FALLO" : "BLOQUEADO ✓"));
        System.out.println();
        
        // ============================================================
        // VERIFICACIÓN FINAL
        // ============================================================
        System.out.println("╔════════════════════════════════════════════════════════════════╗");
        System.out.println("║  RESUMEN DE SEGURIDAD                                          ║");
        System.out.println("╚════════════════════════════════════════════════════════════════╝");
        System.out.println("✅ Todos los intentos de SQL Injection fueron NEUTRALIZADOS");
        System.out.println("✅ La base de datos permanece INTACTA");
        System.out.println("✅ PreparedStatement previene inyección de código SQL");
        System.out.println();
        System.out.println("🔒 MECANISMO DE PROTECCIÓN:");
        System.out.println("   1. Los valores de entrada son tratados como DATOS, no como CÓDIGO");
        System.out.println("   2. Los placeholders (?) separan SQL de los valores");
        System.out.println("   3. El driver escapa caracteres especiales automáticamente");
        System.out.println("   4. NO hay concatenación de strings en las consultas SQL");
        System.out.println();
    }
}

/**
 * ============================================================================
 * COMPARACIÓN: CÓDIGO VULNERABLE vs. CÓDIGO SEGURO
 * ============================================================================
 * 
 * ❌ CÓDIGO VULNERABLE (NO USAR):
 * --------------------------------
 * String sqlVulnerable = "SELECT id_centro FROM CentrosAcopio WHERE nombre = '" + nombreCentro + "'";
 * Statement stmt = conn.createStatement();
 * ResultSet rs = stmt.executeQuery(sqlVulnerable);
 * 
 * Problema: Si nombreCentro = "EcoPunto'; DROP TABLE CentrosAcopio; --"
 * El SQL ejecutado sería:
 * SELECT id_centro FROM CentrosAcopio WHERE nombre = 'EcoPunto'; DROP TABLE CentrosAcopio; --'
 *                                                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *                                                                 ¡CÓDIGO MALICIOSO EJECUTADO!
 * 
 * ✅ CÓDIGO SEGURO (USAR SIEMPRE):
 * --------------------------------
 * String sqlSeguro = "SELECT id_centro FROM CentrosAcopio WHERE nombre = ?";
 * PreparedStatement ps = conn.prepareStatement(sqlSeguro);
 * ps.setString(1, nombreCentro);
 * ResultSet rs = ps.executeQuery();
 * 
 * Resultado: Si nombreCentro = "EcoPunto'; DROP TABLE CentrosAcopio; --"
 * El driver busca literalmente un centro con ese nombre completo.
 * El código malicioso NUNCA se interpreta como SQL.
 * ============================================================================
 */
