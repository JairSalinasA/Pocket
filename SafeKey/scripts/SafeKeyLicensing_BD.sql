-- =============================================
-- SCRIPT COMPLETO: SafeKeyLicensing Multi-Tenant
-- INCLUYENDO CREATE DATABASE
-- =============================================

-- =============================================
-- CREAR BASE DE DATOS (SI NO EXISTE)
-- =============================================

DO $$ 
BEGIN
    -- Intentar crear la base de datos
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'SafeKeyLicensing') THEN
        CREATE DATABASE "SafeKeyLicensing"
            WITH
            OWNER = postgres
            ENCODING = 'UTF8'
            LOCALE_PROVIDER = 'libc'
            CONNECTION LIMIT = -1
            IS_TEMPLATE = False;
        
        RAISE NOTICE '✅ Base de datos "SafeKeyLicensing" creada exitosamente';
    ELSE
        RAISE NOTICE '📊 Base de datos "SafeKeyLicensing" ya existe';
    END IF;
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '⚠️  No se pudo crear la base de datos. Verifica permisos.';
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error creando base de datos: %', SQLERRM;
END $$;

-- =============================================
-- CONECTAR A LA BASE DE DATOS
-- =============================================

\c "SafeKeyLicensing";

-- =============================================
-- ELIMINAR TABLAS EXISTENTES (SI ES NECESARIO)
-- =============================================

DROP VIEW IF EXISTS "VW_PagosRecientes" CASCADE;
DROP VIEW IF EXISTS "VW_EstadisticasPorTenant" CASCADE;

DROP TABLE IF EXISTS "Pagos" CASCADE;
DROP TABLE IF EXISTS "Heartbeats" CASCADE;
DROP TABLE IF EXISTS "Logs" CASCADE;
DROP TABLE IF EXISTS "Configuraciones" CASCADE;
DROP TABLE IF EXISTS "LicenciasActivas" CASCADE;
DROP TABLE IF EXISTS "Solicitudes" CASCADE;
DROP TABLE IF EXISTS "Software" CASCADE;
DROP TABLE IF EXISTS "TiposLicencia" CASCADE;
DROP TABLE IF EXISTS "Tenants" CASCADE;

DROP FUNCTION IF EXISTS "GenerarIdPago" CASCADE;
DROP FUNCTION IF EXISTS "VerificarLimitesTenant" CASCADE;
DROP FUNCTION IF EXISTS "ActualizarFechaPago" CASCADE;

-- =============================================
-- TABLA PRINCIPAL: TENANTS
-- =============================================

CREATE TABLE IF NOT EXISTS "Tenants" (
    "Id" SERIAL PRIMARY KEY,
    "Nombre" VARCHAR(200) NOT NULL,
    "TenantId" VARCHAR(100) NOT NULL UNIQUE,
    "Descripcion" TEXT NULL,
    "ContactEmail" VARCHAR(256) NULL,
    "Website" VARCHAR(500) NULL,
    "LogoUrl" VARCHAR(500) NULL,
    
    -- Configuración y límites
    "MaxLicencias" INTEGER NOT NULL DEFAULT 100,
    "MaxUsuarios" INTEGER NOT NULL DEFAULT 10,
    "MaxSoftwares" INTEGER NOT NULL DEFAULT 5,
    "Plan" VARCHAR(50) NOT NULL DEFAULT 'Free',
    "Activo" BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Información de pagos
    "StripeCustomerId" VARCHAR(100) NULL,
    "PaypalEmail" VARCHAR(256) NULL,
    
    -- Fechas
    "FechaCreacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    "FechaExpiracion" TIMESTAMP NULL,
    "FechaActualizacion" TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =============================================
-- TABLAS DEL SISTEMA MULTI-TENANT
-- =============================================

CREATE TABLE IF NOT EXISTS "TiposLicencia" (
    "Id" SERIAL PRIMARY KEY,
    "Nombre" VARCHAR(100) NOT NULL,
    "Codigo" VARCHAR(50) NOT NULL,
    "PrecioMin" DECIMAL(10,2) NOT NULL,
    "PrecioMax" DECIMAL(10,2) NOT NULL,
    "Descripcion" VARCHAR(500) NULL,
    "DuracionDias" INTEGER NOT NULL DEFAULT 30,
    "Activo" BOOLEAN NOT NULL DEFAULT TRUE,
    "FechaCreacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    "TenantId" INTEGER NOT NULL,
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE,
    CONSTRAINT "UK_TiposLicencia_Tenant_Codigo" UNIQUE ("TenantId", "Codigo")
);

CREATE TABLE IF NOT EXISTS "Software" (
    "Id" SERIAL PRIMARY KEY,
    "Nombre" VARCHAR(200) NOT NULL,
    "Codigo" VARCHAR(100) NOT NULL,
    "Version" VARCHAR(50) NOT NULL,
    "Descripcion" VARCHAR(500) NULL,
    "Activo" BOOLEAN NOT NULL DEFAULT TRUE,
    "FechaCreacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    "TenantId" INTEGER NOT NULL,
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE,
    CONSTRAINT "UK_Software_Tenant_Codigo" UNIQUE ("TenantId", "Codigo")
);

CREATE TABLE IF NOT EXISTS "Solicitudes" (
    "Id" SERIAL PRIMARY KEY,
    "SolicitudId" VARCHAR(50) NOT NULL,
    "UsuarioId" TEXT NOT NULL,
    "SoftwareId" INTEGER NOT NULL,
    "TipoLicenciaId" INTEGER NOT NULL,
    "NombreCliente" VARCHAR(200) NOT NULL,
    "EmailCliente" VARCHAR(256) NOT NULL,
    "IPAddress" VARCHAR(45) NULL,
    "HDDId" VARCHAR(100) NULL,
    "MotherboardId" VARCHAR(100) NULL,
    "Precio" DECIMAL(10,2) NOT NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Pendiente',
    "FechaSolicitud" TIMESTAMP NOT NULL DEFAULT NOW(),
    "FechaAprobacion" TIMESTAMP NULL,
    "MotivoRechazo" VARCHAR(500) NULL,
    
    "TenantId" INTEGER NOT NULL,
    FOREIGN KEY ("SoftwareId") REFERENCES "Software"("Id"),
    FOREIGN KEY ("TipoLicenciaId") REFERENCES "TiposLicencia"("Id"),
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE,
    CONSTRAINT "UK_Solicitudes_Tenant_SolicitudId" UNIQUE ("TenantId", "SolicitudId")
);

CREATE TABLE IF NOT EXISTS "LicenciasActivas" (
    "Id" SERIAL PRIMARY KEY,
    "LicenciaId" VARCHAR(50) NOT NULL,
    "SolicitudId" INTEGER NOT NULL,
    "ApiKey" VARCHAR(100) NOT NULL,
    "HardwareInfo" VARCHAR(500) NOT NULL,
    "TipoLicenciaId" INTEGER NOT NULL,
    "FechaInicio" TIMESTAMP NOT NULL DEFAULT NOW(),
    "FechaVencimiento" TIMESTAMP NOT NULL,
    "Status" VARCHAR(50) NOT NULL DEFAULT 'ACTIVA',
    "UltimoHeartbeat" TIMESTAMP NULL,
    "IntentosHeartbeatFallidos" INTEGER NOT NULL DEFAULT 0,
    "FechaCreacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    "TenantId" INTEGER NOT NULL,
    FOREIGN KEY ("SolicitudId") REFERENCES "Solicitudes"("Id"),
    FOREIGN KEY ("TipoLicenciaId") REFERENCES "TiposLicencia"("Id"),
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE,
    CONSTRAINT "UK_LicenciasActivas_Tenant_LicenciaId" UNIQUE ("TenantId", "LicenciaId"),
    CONSTRAINT "UK_LicenciasActivas_Tenant_ApiKey" UNIQUE ("TenantId", "ApiKey")
);

-- =============================================
-- TABLA: PAGOS
-- =============================================

CREATE TABLE IF NOT EXISTS "Pagos" (
    "Id" SERIAL PRIMARY KEY,
    "PagoId" VARCHAR(100) NOT NULL UNIQUE,
    "TenantId" INTEGER NOT NULL,
    "UsuarioId" TEXT NOT NULL,
    
    -- Información del pago
    "Monto" DECIMAL(10,2) NOT NULL,
    "Moneda" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "Concepto" VARCHAR(500) NOT NULL,
    "MetodoPago" VARCHAR(50) NOT NULL,
    "ReferenciaExterna" VARCHAR(200) NULL,
    
    -- Estados del pago
    "Status" VARCHAR(50) NOT NULL DEFAULT 'Pendiente',
    "FechaPago" TIMESTAMP NULL,
    "FechaExpiracion" TIMESTAMP NULL,
    
    -- Información de la transacción
    "DatosTransaccion" JSONB NULL,
    "Error" TEXT NULL,
    
    -- Auditoría
    "FechaCreacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    "FechaActualizacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE
);

-- =============================================
-- TABLAS DE AUDITORÍA Y LOGS
-- =============================================

CREATE TABLE IF NOT EXISTS "Heartbeats" (
    "Id" SERIAL PRIMARY KEY,
    "LicenciaActivaId" INTEGER NOT NULL,
    "Fecha" TIMESTAMP NOT NULL DEFAULT NOW(),
    "IPAddress" VARCHAR(45) NULL,
    "HardwareInfo" VARCHAR(500) NULL,
    "EsValido" BOOLEAN NOT NULL,
    "Mensaje" VARCHAR(500) NULL,
    "TenantId" INTEGER NOT NULL,
    
    FOREIGN KEY ("LicenciaActivaId") REFERENCES "LicenciasActivas"("Id") ON DELETE CASCADE,
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "Logs" (
    "Id" SERIAL PRIMARY KEY,
    "Fecha" TIMESTAMP NOT NULL DEFAULT NOW(),
    "Nivel" VARCHAR(50) NOT NULL,
    "Mensaje" VARCHAR(1000) NOT NULL,
    "Detalles" TEXT NULL,
    "IPAddress" VARCHAR(45) NULL,
    "UserAgent" VARCHAR(500) NULL,
    "UsuarioId" TEXT NULL,
    "TenantId" INTEGER NOT NULL,
    
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "Configuraciones" (
    "Id" SERIAL PRIMARY KEY,
    "Clave" VARCHAR(100) NOT NULL,
    "Valor" VARCHAR(500) NOT NULL,
    "Descripcion" VARCHAR(500) NULL,
    "FechaActualizacion" TIMESTAMP NOT NULL DEFAULT NOW(),
    "TenantId" INTEGER NOT NULL,
    
    FOREIGN KEY ("TenantId") REFERENCES "Tenants"("Id") ON DELETE CASCADE,
    CONSTRAINT "UK_Configuraciones_Tenant_Clave" UNIQUE ("TenantId", "Clave")
);

-- =============================================
-- ÍNDICES MULTI-TENANT OPTIMIZADOS
-- =============================================

DO $$ 
BEGIN
    -- Índices para consultas multi-tenant rápidas
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Tenants_TenantId') THEN
        CREATE INDEX "IX_Tenants_TenantId" ON "Tenants" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Software_TenantId') THEN
        CREATE INDEX "IX_Software_TenantId" ON "Software" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_TiposLicencia_TenantId') THEN
        CREATE INDEX "IX_TiposLicencia_TenantId" ON "TiposLicencia" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Solicitudes_TenantId') THEN
        CREATE INDEX "IX_Solicitudes_TenantId" ON "Solicitudes" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_LicenciasActivas_TenantId') THEN
        CREATE INDEX "IX_LicenciasActivas_TenantId" ON "LicenciasActivas" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Pagos_TenantId') THEN
        CREATE INDEX "IX_Pagos_TenantId" ON "Pagos" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Heartbeats_TenantId') THEN
        CREATE INDEX "IX_Heartbeats_TenantId" ON "Heartbeats" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Logs_TenantId') THEN
        CREATE INDEX "IX_Logs_TenantId" ON "Logs" ("TenantId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Configuraciones_TenantId') THEN
        CREATE INDEX "IX_Configuraciones_TenantId" ON "Configuraciones" ("TenantId");
    END IF;
    
    -- Índices compuestos para consultas específicas
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_LicenciasActivas_Tenant_Status') THEN
        CREATE INDEX "IX_LicenciasActivas_Tenant_Status" ON "LicenciasActivas" ("TenantId", "Status");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Solicitudes_Tenant_Status') THEN
        CREATE INDEX "IX_Solicitudes_Tenant_Status" ON "Solicitudes" ("TenantId", "Status");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_LicenciasActivas_Tenant_FechaVencimiento') THEN
        CREATE INDEX "IX_LicenciasActivas_Tenant_FechaVencimiento" ON "LicenciasActivas" ("TenantId", "FechaVencimiento");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Pagos_Tenant_Status') THEN
        CREATE INDEX "IX_Pagos_Tenant_Status" ON "Pagos" ("TenantId", "Status");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Pagos_UsuarioId') THEN
        CREATE INDEX "IX_Pagos_UsuarioId" ON "Pagos" ("UsuarioId");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Pagos_ReferenciaExterna') THEN
        CREATE INDEX "IX_Pagos_ReferenciaExterna" ON "Pagos" ("ReferenciaExterna");
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'IX_Pagos_FechaPago') THEN
        CREATE INDEX "IX_Pagos_FechaPago" ON "Pagos" ("FechaPago");
    END IF;
    
END $$;

-- =============================================
-- DATOS INICIALES MULTI-TENANT
-- =============================================

DO $$ 
BEGIN
    -- Insertar tenant principal solo si no existe
    IF NOT EXISTS (SELECT 1 FROM "Tenants" WHERE "TenantId" = 'default') THEN
        INSERT INTO "Tenants" ("Id", "Nombre", "TenantId", "Descripcion", "MaxLicencias", "MaxUsuarios", "MaxSoftwares", "Plan") VALUES
        (1, 'Tenant Principal', 'default', 'Tenant principal del sistema', 1000, 100, 50, 'Enterprise');
    END IF;
    
    -- Insertar tipos de licencia para el tenant principal
    IF NOT EXISTS (SELECT 1 FROM "TiposLicencia" WHERE "TenantId" = 1 AND "Codigo" = 'LIC-0001') THEN
        INSERT INTO "TiposLicencia" ("Nombre", "Codigo", "PrecioMin", "PrecioMax", "Descripcion", "DuracionDias", "TenantId") VALUES
        ('Básica', 'LIC-0001', 10.00, 10.00, 'Acceso a funciones core, soporte básico por email, uso personal o para 1 proyecto.', 30, 1),
        ('Profesional', 'LIC-0002', 10.00, 30.00, 'Licencia profesional con características avanzadas y soporte prioritario.', 30, 1),
        ('Premium', 'LIC-0003', 60.00, 100.00, 'Licencia para múltiples usuarios/instalaciones, soporte 24/7, plugins premium incluidos.', 30, 1),
        ('Enterprise', 'LIC-0004', 300.00, 500.00, 'Licencia empresarial con soporte prioritario y características enterprise.', 30, 1);
    END IF;
    
    -- Insertar software para el tenant principal
    IF NOT EXISTS (SELECT 1 FROM "Software" WHERE "TenantId" = 1 AND "Codigo" = 'SOFT-PERS-001') THEN
        INSERT INTO "Software" ("Nombre", "Codigo", "Version", "Descripcion", "TenantId") VALUES
        ('Software Personal', 'SOFT-PERS-001', '1.0', 'Software para uso personal y proyectos individuales', 1),
        ('Software Empresarial', 'SOFT-EMP-001', '2.0', 'Software para uso empresarial con múltiples usuarios', 1);
    END IF;
    
    -- Configuraciones por tenant
    IF NOT EXISTS (SELECT 1 FROM "Configuraciones" WHERE "TenantId" = 1 AND "Clave" = 'AdminKey') THEN
        INSERT INTO "Configuraciones" ("Clave", "Valor", "Descripcion", "TenantId") VALUES
        ('AdminKey', 'clave-admin-segura-0xm0qotl6mmn', 'Llave maestra para operaciones administrativas', 1),
        ('ToleranciaHeartbeatMinutos', '60', 'Tiempo en minutos permitido sin heartbeat antes de marcar como expirada', 1),
        ('EmailNotificaciones', 'notificaciones@safekey.com', 'Email para envío de notificaciones', 1);
    END IF;
    
END $$;

-- =============================================
-- VISTAS MULTI-TENANT
-- =============================================

CREATE OR REPLACE VIEW "VW_EstadisticasPorTenant" AS
SELECT 
    t."Id" as "TenantId",
    t."Nombre" as "TenantNombre",
    t."Plan",
    COUNT(DISTINCT s."Id") as "TotalSoftwares",
    COUNT(DISTINCT sol."Id") as "TotalSolicitudes",
    COUNT(DISTINCT la."Id") as "TotalLicencias",
    COUNT(DISTINCT CASE WHEN la."Status" = 'ACTIVA' THEN la."Id" END) as "LicenciasActivas",
    COUNT(DISTINCT p."Id") as "TotalPagos",
    SUM(CASE WHEN p."Status" = 'Completado' THEN p."Monto" ELSE 0 END) as "IngresosTotales",
    t."MaxLicencias" as "LimiteLicencias",
    t."MaxUsuarios" as "LimiteUsuarios",
    t."MaxSoftwares" as "LimiteSoftwares"
FROM "Tenants" t
LEFT JOIN "Software" s ON t."Id" = s."TenantId"
LEFT JOIN "Solicitudes" sol ON t."Id" = sol."TenantId"
LEFT JOIN "LicenciasActivas" la ON t."Id" = la."TenantId"
LEFT JOIN "Pagos" p ON t."Id" = p."TenantId"
GROUP BY t."Id", t."Nombre", t."Plan", t."MaxLicencias", t."MaxUsuarios", t."MaxSoftwares";

CREATE OR REPLACE VIEW "VW_PagosRecientes" AS
SELECT 
    t."TenantId",
    t."Nombre" as "TenantNombre",
    p."PagoId",
    p."Monto",
    p."Moneda",
    p."Concepto",
    p."MetodoPago",
    p."Status",
    p."FechaPago",
    p."FechaCreacion"
FROM "Pagos" p
INNER JOIN "Tenants" t ON p."TenantId" = t."Id"
WHERE p."FechaCreacion" >= (NOW() - INTERVAL '30 days')
ORDER BY p."FechaCreacion" DESC;

-- =============================================
-- FUNCIONES MULTI-TENANT
-- =============================================

CREATE OR REPLACE FUNCTION "GenerarIdPago"()
RETURNS VARCHAR(100) AS $$
DECLARE
    nuevo_id VARCHAR(100);
    ultimo_num INTEGER;
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING("PagoId" FROM 5) AS INTEGER)), 0) 
    INTO ultimo_num 
    FROM "Pagos"
    WHERE "PagoId" LIKE 'PAG-%';
    
    nuevo_id := 'PAG-' || LPAD((ultimo_num + 1)::TEXT, 4, '0');
    RETURN nuevo_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "VerificarLimitesTenant"(
    p_tenant_id INTEGER,
    p_tipo_limite VARCHAR(50)
)
RETURNS TABLE(
    puede_crear BOOLEAN,
    mensaje VARCHAR(500),
    actual INTEGER,
    maximo INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN p_tipo_limite = 'LICENCIAS' THEN estad."TotalLicencias" < estad."LimiteLicencias"
            WHEN p_tipo_limite = 'SOFTWARES' THEN estad."TotalSoftwares" < estad."LimiteSoftwares"
            ELSE FALSE
        END as puede_crear,
        CASE 
            WHEN p_tipo_limite = 'LICENCIAS' AND estad."TotalLicencias" >= estad."LimiteLicencias" THEN
                'Límite de licencias alcanzado (' || estad."TotalLicencias" || '/' || estad."LimiteLicencias" || ')'
            WHEN p_tipo_limite = 'SOFTWARES' AND estad."TotalSoftwares" >= estad."LimiteSoftwares" THEN
                'Límite de softwares alcanzado (' || estad."TotalSoftwares" || '/' || estad."LimiteSoftwares" || ')'
            ELSE 'Puede crear'
        END as mensaje,
        CASE 
            WHEN p_tipo_limite = 'LICENCIAS' THEN estad."TotalLicencias"
            WHEN p_tipo_limite = 'SOFTWARES' THEN estad."TotalSoftwares"
            ELSE 0
        END as actual,
        CASE 
            WHEN p_tipo_limite = 'LICENCIAS' THEN estad."LimiteLicencias"
            WHEN p_tipo_limite = 'SOFTWARES' THEN estad."LimiteSoftwares"
            ELSE 0
        END as maximo
    FROM "VW_EstadisticasPorTenant" estad
    WHERE estad."TenantId" = p_tenant_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TRIGGERS
-- =============================================

CREATE OR REPLACE FUNCTION "ActualizarFechaPago"()
RETURNS TRIGGER AS $$
BEGIN
    NEW."FechaActualizacion" = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "TR_Pagos_ActualizarFecha" ON "Pagos";
CREATE TRIGGER "TR_Pagos_ActualizarFecha"
    BEFORE UPDATE ON "Pagos"
    FOR EACH ROW
    EXECUTE FUNCTION "ActualizarFechaPago"();

-- =============================================
-- VERIFICACIÓN FINAL
-- =============================================

DO $$ 
DECLARE
    tabla_count INTEGER;
    indice_count INTEGER;
    db_exists BOOLEAN;
BEGIN
    -- Verificar si la base de datos existe
    SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = 'SafeKeyLicensing') INTO db_exists;
    
    -- Contar tablas creadas
    SELECT COUNT(*) INTO tabla_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    -- Contar índices creados
    SELECT COUNT(*) INTO indice_count 
    FROM pg_indexes 
    WHERE schemaname = 'public';
    
    RAISE NOTICE '=========================================';
    RAISE NOTICE '✅ SISTEMA COMPLETO CREADO EXITOSAMENTE';
    RAISE NOTICE '=========================================';
    RAISE NOTICE '🗄️  Base de datos: %', CASE WHEN db_exists THEN 'SafeKeyLicensing ✅' ELSE 'No creada ❌' END;
    RAISE NOTICE '🏢 Tablas creadas: %', tabla_count;
    RAISE NOTICE '📊 Vistas creadas: 2';
    RAISE NOTICE '🔧 Funciones creadas: 2';
    RAISE NOTICE '⚡ Índices creados: %', indice_count;
    RAISE NOTICE '💳 Incluye tabla: Pagos';
    RAISE NOTICE '🎯 Tenant principal: default';
    RAISE NOTICE '🛡️ Script idempotente: ✅';
    RAISE NOTICE '🚫 Identity tables: Serán creadas por .NET';
    RAISE NOTICE '=========================================';
    
    -- Mostrar resumen de tablas
    IF tabla_count > 0 THEN
        RAISE NOTICE '📋 TABLAS CREADAS:';
        FOR tabla IN 
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name
        LOOP
            RAISE NOTICE '   - %', tabla.table_name;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ No se crearon tablas. Verifica errores.';
    END IF;
    
END $$;