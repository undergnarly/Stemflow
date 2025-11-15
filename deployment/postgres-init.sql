-- Production Tracker - PostgreSQL Initialization Script
-- This script runs when the database is first created

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For better indexing

-- Create custom functions for timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Performance tuning (will be overridden by Docker env vars)
-- These are just defaults
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- Logging configuration
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1s
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';
ALTER SYSTEM SET log_checkpoints = on;
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM SET log_temp_files = 0;

-- Connection limits
ALTER SYSTEM SET max_connections = 100;

-- Reload configuration
SELECT pg_reload_conf();

-- Create production user (optional - comment out if using default postgres user)
-- CREATE USER pt_user WITH PASSWORD 'change_this_password';
-- GRANT ALL PRIVILEGES ON DATABASE production_tracker TO pt_user;

-- Helpful views for monitoring

-- View for table sizes
CREATE OR REPLACE VIEW table_sizes AS
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_total_relation_size(schemaname||'.'||tablename) AS size_bytes
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- View for active connections
CREATE OR REPLACE VIEW active_connections AS
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query,
    query_start,
    state_change
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- View for slow queries
CREATE OR REPLACE VIEW slow_queries AS
SELECT
    pid,
    now() - query_start AS duration,
    usename,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
  AND now() - query_start > interval '5 seconds'
ORDER BY duration DESC;

-- Grant access to views
GRANT SELECT ON table_sizes TO PUBLIC;
GRANT SELECT ON active_connections TO PUBLIC;
GRANT SELECT ON slow_queries TO PUBLIC;

-- Helpful functions

-- Function to cancel long-running queries
CREATE OR REPLACE FUNCTION cancel_long_queries(max_duration interval DEFAULT '10 minutes')
RETURNS TABLE(pid integer, duration interval, query text) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pg_stat_activity.pid,
        now() - pg_stat_activity.query_start AS duration,
        pg_stat_activity.query
    FROM pg_stat_activity
    WHERE state != 'idle'
      AND now() - pg_stat_activity.query_start > max_duration
      AND pg_cancel_backend(pg_stat_activity.pid);
END;
$$ LANGUAGE plpgsql;

-- Vacuum and analyze on startup
VACUUM ANALYZE;

-- Output success message
DO $$
BEGIN
    RAISE NOTICE 'Production Tracker database initialized successfully';
    RAISE NOTICE 'Database version: %', version();
    RAISE NOTICE 'Current time: %', now();
END $$;
