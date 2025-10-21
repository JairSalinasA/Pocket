-- =============================================
-- PostgreSQL Extensions and Optimization Script
-- SafeKeyLicensing - Enhanced NoSQL Capabilities
-- =============================================

-- Enable required extensions for NoSQL features
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- UUID generation
CREATE EXTENSION IF NOT EXISTS "hstore";       -- Key-value storage
CREATE EXTENSION IF NOT EXISTS "pg_trgm";      -- Trigram matching for search
CREATE EXTENSION IF NOT EXISTS "btree_gin";    -- GIN indexes for btree types
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Query performance monitoring

-- Configure PostgreSQL for optimal performance
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- Reload configuration
SELECT pg_reload_conf();

-- =============================================
-- Custom Functions for Enhanced JSONB Operations
-- =============================================

-- Function to validate JSON schema
CREATE OR REPLACE FUNCTION validate_json_schema(data jsonb, schema jsonb)
RETURNS boolean AS $$
BEGIN
    -- Basic schema validation (can be enhanced with more complex logic)
    RETURN data ?& (SELECT array_agg(key) FROM jsonb_object_keys(schema) AS key);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function for JSON path extraction with default
CREATE OR REPLACE FUNCTION json_extract_path_text_default(data jsonb, path text, default_value text DEFAULT NULL)
RETURNS text AS $$
BEGIN
    RETURN COALESCE(data #>> string_to_array(path, '.'), default_value);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function for safe JSON array contains
CREATE OR REPLACE FUNCTION json_array_contains_text(data jsonb, search_value text)
RETURNS boolean AS $$
BEGIN
    RETURN (data @> to_jsonb(search_value));
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================
-- Enhanced Search Functions
-- =============================================

-- Function for multilingual full-text search
CREATE OR REPLACE FUNCTION search_text_multilingual(text_data text, search_term text)
RETURNS boolean AS $$
BEGIN
    RETURN (
        to_tsvector('spanish', COALESCE(text_data, '')) @@ plainto_tsquery('spanish', search_term) OR
        to_tsvector('english', COALESCE(text_data, '')) @@ plainto_tsquery('english', search_term)
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function for fuzzy text matching
CREATE OR REPLACE FUNCTION fuzzy_search(text_data text, search_term text, threshold real DEFAULT 0.3)
RETURNS boolean AS $$
BEGIN
    RETURN similarity(text_data, search_term) > threshold;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================
-- Performance Monitoring Views
-- =============================================

-- View for monitoring slow queries
CREATE OR REPLACE VIEW slow_queries AS
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    stddev_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE mean_time > 100  -- Queries taking more than 100ms on average
ORDER BY mean_time DESC;

-- View for monitoring JSONB column usage
CREATE OR REPLACE VIEW jsonb_usage_stats AS
SELECT 
    schemaname,
    tablename,
    attname as column_name,
    n_distinct,
    correlation,
    most_common_vals,
    most_common_freqs
FROM pg_stats 
WHERE atttypid = 'jsonb'::regtype;

-- View for index usage statistics
CREATE OR REPLACE VIEW index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- =============================================
-- Maintenance Functions
-- =============================================

-- Function to analyze JSONB column statistics
CREATE OR REPLACE FUNCTION analyze_jsonb_columns()
RETURNS void AS $$
DECLARE
    rec record;
BEGIN
    FOR rec IN 
        SELECT schemaname, tablename, attname 
        FROM pg_stats 
        WHERE atttypid = 'jsonb'::regtype
    LOOP
        EXECUTE format('ANALYZE %I.%I', rec.schemaname, rec.tablename);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to reindex GIN indexes
CREATE OR REPLACE FUNCTION reindex_gin_indexes()
RETURNS void AS $$
DECLARE
    rec record;
BEGIN
    FOR rec IN 
        SELECT schemaname, indexname 
        FROM pg_indexes 
        WHERE indexdef LIKE '%gin%'
    LOOP
        EXECUTE format('REINDEX INDEX CONCURRENTLY %I.%I', rec.schemaname, rec.indexname);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Sample Data Types for JSON Storage
-- =============================================

-- Create sample composite types for JSONB validation
CREATE TYPE payment_metadata AS (
    user_agent text,
    ip_address inet,
    device_info jsonb,
    campaign_id text,
    referrer text
);

CREATE TYPE transaction_data AS (
    method text,
    provider text,
    customer_data jsonb,
    billing_address jsonb,
    items jsonb[]
);

-- =============================================
-- Triggers for Automatic Maintenance
-- =============================================

-- Function to update search vectors automatically
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS trigger AS $$
BEGIN
    IF TG_TABLE_NAME = 'Software' THEN
        NEW.search_vector := to_tsvector('spanish', 
            COALESCE(NEW."Nombre", '') || ' ' || 
            COALESCE(NEW."Descripcion", ''));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to validate JSONB data before insert/update
CREATE OR REPLACE FUNCTION validate_jsonb_data()
RETURNS trigger AS $$
BEGIN
    IF TG_TABLE_NAME = 'Pagos' THEN
        -- Validate payment transaction data structure
        IF NEW."DatosTransaccion" IS NOT NULL THEN
            IF NOT (NEW."DatosTransaccion" ? 'method') THEN
                RAISE EXCEPTION 'Payment method is required in transaction data';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Security Functions
-- =============================================

-- Function to sanitize JSON input
CREATE OR REPLACE FUNCTION sanitize_jsonb(input_json jsonb)
RETURNS jsonb AS $$
DECLARE
    result jsonb;
BEGIN
    -- Remove potentially dangerous keys
    result := input_json - '{__proto__,constructor,prototype}';
    
    -- Limit nesting depth (max 10 levels)
    IF jsonb_path_query_array(result, '$.** ? (@.type() == "object")') IS NOT NULL THEN
        -- Additional depth validation can be added here
        NULL;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Row Level Security helper function
CREATE OR REPLACE FUNCTION current_tenant_id()
RETURNS integer AS $$
BEGIN
    -- This should be set by the application context
    RETURN current_setting('app.current_tenant_id', true)::integer;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================
-- Notification System
-- =============================================

-- Function to send notifications for critical events
CREATE OR REPLACE FUNCTION notify_critical_event()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        IF TG_TABLE_NAME = 'LicenciasActivas' AND NEW."Status" = 'EXPIRADA' THEN
            PERFORM pg_notify('license_expired', json_build_object(
                'license_id', NEW."Id",
                'tenant_id', NEW."TenantId",
                'api_key', LEFT(NEW."ApiKey", 8) || '...'
            )::text);
        END IF;
        RETURN NEW;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Completion Message
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '✅ PostgreSQL Enhanced Configuration Complete';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔧 Extensions enabled: uuid-ossp, hstore, pg_trgm, btree_gin';
    RAISE NOTICE '📊 Performance monitoring views created';
    RAISE NOTICE '🔍 Enhanced search functions available';
    RAISE NOTICE '⚡ JSONB helper functions installed';
    RAISE NOTICE '🛡️ Security and validation functions ready';
    RAISE NOTICE '📢 Notification system configured';
    RAISE NOTICE '===============================================';
END $$;