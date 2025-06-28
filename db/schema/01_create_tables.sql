-- Licensed under the Apache License, Version 2.0
-- See http://www.apache.org/licenses/LICENSE-2.0 for details

-- Create schema for job scheduler
CREATE SCHEMA IF NOT EXISTS scheduler;

-- Optional: Set search_path for this session
-- SET search_path TO scheduler;

-- Track schema versioning
CREATE TABLE scheduler.schema_version (
    id SERIAL PRIMARY KEY,
    version TEXT NOT NULL,
    applied_at TIMESTAMP DEFAULT now(),
    description TEXT
);
COMMENT ON TABLE scheduler.schema_version IS 'Tracks schema versions applied to the scheduler database.';

-- Table: jobs
CREATE TABLE scheduler.jobs (
    id SERIAL PRIMARY KEY,
    job_name TEXT NOT NULL UNIQUE,
    description TEXT,
    run_as_user TEXT,
    base_directory TEXT,
    enforce_path_security BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE scheduler.jobs IS 'Stores job-level metadata.';
COMMENT ON COLUMN scheduler.jobs.job_name IS 'Unique name identifying the job.';
COMMENT ON COLUMN scheduler.jobs.run_as_user IS 'User context under which the job should execute.';
COMMENT ON COLUMN scheduler.jobs.enforce_path_security IS 'If TRUE, ensures paths are within base_directory.';

-- Table: triggers
CREATE TABLE scheduler.triggers (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('time', 'event', 'dependency')),
    schedule TEXT,
    event_source TEXT,
    dependent_job_name TEXT
);
COMMENT ON TABLE scheduler.triggers IS 'Defines how and when a job is triggered.';
COMMENT ON COLUMN scheduler.triggers.type IS 'Trigger type: time-based, event-based, or dependency-based.';
COMMENT ON COLUMN scheduler.triggers.schedule IS 'Cron-style expression for time triggers.';

-- Table: result_conditions
CREATE TABLE scheduler.result_conditions (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    success_max_return_code INTEGER DEFAULT 0,
    warning_max_return_code INTEGER
);
COMMENT ON TABLE scheduler.result_conditions IS 'Defines result code thresholds for job success or warnings.';

-- Table: step_exceptions
CREATE TABLE scheduler.step_exceptions (
    id SERIAL PRIMARY KEY,
    result_condition_id INTEGER NOT NULL REFERENCES scheduler.result_conditions(id) ON DELETE CASCADE,
    step_name TEXT,
    success_max_return_code INTEGER,
    warning_max_return_code INTEGER
);
COMMENT ON TABLE scheduler.step_exceptions IS 'Overrides global result conditions for specific steps.';

-- Table: steps
CREATE TABLE scheduler.steps (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    args TEXT[],
    working_directory TEXT,
    run_as_user TEXT,
    run_if_previous TEXT
);
COMMENT ON TABLE scheduler.steps IS 'Defines executable steps in a job.';
COMMENT ON COLUMN scheduler.steps.run_if_previous IS 'Conditional expression determining if the step should run based on prior step results.';

-- Table: conditions
CREATE TABLE scheduler.conditions (
    id SERIAL PRIMARY KEY,
    step_id INTEGER NOT NULL REFERENCES scheduler.steps(id) ON DELETE CASCADE,
    operator TEXT NOT NULL
);
COMMENT ON TABLE scheduler.conditions IS 'Logical condition used to control execution of a step.';
COMMENT ON COLUMN scheduler.conditions.operator IS 'Logical operator such as AND, OR to evaluate condition operands.';

-- Table: operands
CREATE TABLE scheduler.operands (
    id SERIAL PRIMARY KEY,
    condition_id INTEGER NOT NULL REFERENCES scheduler.conditions(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    step_name TEXT,
    comparison TEXT,
    value TEXT
);
COMMENT ON TABLE scheduler.operands IS 'Operands that form part of a step condition.';

-- Table: retry_policies
CREATE TABLE scheduler.retry_policies (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    step_id INTEGER REFERENCES scheduler.steps(id) ON DELETE CASCADE,
    max_attempts INTEGER DEFAULT 1,
    delay_seconds INTEGER DEFAULT 0,
    backoff_factor REAL DEFAULT 1.0,
    retry_on TEXT[]
);
COMMENT ON TABLE scheduler.retry_policies IS 'Retry configuration for jobs or individual steps.';

-- Table: log_settings
CREATE TABLE scheduler.log_settings (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    step_id INTEGER REFERENCES scheduler.steps(id) ON DELETE CASCADE,
    stdout TEXT,
    stderr TEXT,
    rotation TEXT,
    destination TEXT
);
COMMENT ON TABLE scheduler.log_settings IS 'Specifies logging preferences for jobs and steps.';
