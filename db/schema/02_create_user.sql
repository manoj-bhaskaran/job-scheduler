-- Licensed under the Apache License, Version 2.0
-- See http://www.apache.org/licenses/LICENSE-2.0 for details

-- NOTE: This script is NOT managed by Flyway.
-- It is intended for local developer setup and initial environment provisioning.
-- Do not include user creation in production migrations.

-- Create application user (read/write access only)
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

GRANT USAGE ON SCHEMA scheduler TO job_scheduler_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA scheduler TO job_scheduler_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA scheduler
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO job_scheduler_app;

-- Create migrator user (for Flyway execution, requires DDL)
DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_roles WHERE rolname = 'job_scheduler_migrator'
    ) THEN
        CREATE USER job_scheduler_migrator;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA scheduler TO job_scheduler_migrator;
GRANT ALL ON ALL TABLES IN SCHEMA scheduler TO job_scheduler_migrator;
GRANT ALL ON ALL SEQUENCES IN SCHEMA scheduler TO job_scheduler_migrator;

ALTER DEFAULT PRIVILEGES IN SCHEMA scheduler
GRANT ALL ON TABLES TO job_scheduler_migrator;

-- scripts/grant_backup_user.sql
GRANT CONNECT ON DATABASE job_scheduler TO backup_user;
GRANT pg_read_all_data TO backup_user;
