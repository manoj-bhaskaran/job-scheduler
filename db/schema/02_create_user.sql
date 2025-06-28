-- db/schema/02_create_user.sql
-- Licensed under the Apache License, Version 2.0

DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = 'job_scheduler_app'
    ) THEN
        CREATE USER job_scheduler_app;
    END IF;
END
$$;

-- Password will be assigned externally if needed

GRANT USAGE ON SCHEMA scheduler TO job_scheduler_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA scheduler TO job_scheduler_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA scheduler
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO job_scheduler_app;
