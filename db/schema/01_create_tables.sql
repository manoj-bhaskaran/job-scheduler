-- Licensed under the Apache License, Version 2.0
-- See http://www.apache.org/licenses/LICENSE-2.0 for details

-- Create schema
CREATE SCHEMA IF NOT EXISTS scheduler;

-- Optional: Set default search_path for this session
-- SET search_path TO scheduler;

-- Table: jobs
CREATE TABLE scheduler.jobs (
    id SERIAL PRIMARY KEY,
    job_name TEXT NOT NULL UNIQUE,
    description TEXT,
    run_as_user TEXT,
    base_directory TEXT,
    enforce_path_security BOOLEAN DEFAULT TRUE
);

-- Table: triggers
CREATE TABLE scheduler.triggers (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('time', 'event', 'dependency')),
    schedule TEXT,
    event_source TEXT,
    dependent_job_name TEXT
);

-- Table: result_conditions
CREATE TABLE scheduler.result_conditions (
    id SERIAL PRIMARY KEY,
    job_id INTEGER NOT NULL REFERENCES scheduler.jobs(id) ON DELETE CASCADE,
    success_max_return_code INTEGER DEFAULT 0,
    warning_max_return_code INTEGER
);

-- Table: step_exceptions
CREATE TABLE scheduler.step_exceptions (
    id SERIAL PRIMARY KEY,
    result_condition_id INTEGER NOT NULL REFERENCES scheduler.result_conditions(id) ON DELETE CASCADE,
    step_name TEXT,
    success_max_return_code INTEGER,
    warning_max_return_code INTEGER
);

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

-- Table: conditions
CREATE TABLE scheduler.conditions (
    id SERIAL PRIMARY KEY,
    step_id INTEGER NOT NULL REFERENCES scheduler.steps(id) ON DELETE CASCADE,
    operator TEXT NOT NULL
);

-- Table: operands
CREATE TABLE scheduler.operands (
    id SERIAL PRIMARY KEY,
    condition_id INTEGER NOT NULL REFERENCES scheduler.conditions(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    step_name TEXT,
    comparison TEXT,
    value TEXT
);

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
