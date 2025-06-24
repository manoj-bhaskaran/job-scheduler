# Job Specification Schema Documentation

This document describes the JSON schema for defining a job specification used by the Windows-based job scheduler.

---

## Top-Level Fields

### `job_name` (string, required)

A unique identifier for the job.

### `description` (string, optional)

Optional free-text description of what the job does.

### `working_directory` (string, optional)

Default working directory for all steps, in Windows format. Must begin with a drive letter, e.g., `C:\jobs\mytask`.

### `run_as_user` (string, required)

Windows user account under which the job will run. Can be domain-qualified. **Pattern:** `^[a-zA-Z0-9\\._-]{1,64}$`

### `base_directory` (string, optional)

Security feature: if set, all `path` and `working_directory` values must be under this base.

### `enforce_path_security` (boolean, default `true`)

If true, ensures all script and working paths fall under `base_directory`.

---

## `trigger` (object, required)

Specifies when and how the job is triggered.

### Fields:

- `type` (required): one of `time`, `event`, `dependency`
- `schedule` (required if type is `time`): cron-style expression (5 to 7 fields supported)
- `event_source` (required if type is `event`): string identifying the source
- `dependent_job_name` (required if type is `dependency`): job name that this depends on

---

## `result_conditions` (object, optional)

Defines what determines job success/warning/failure.

### Fields:

- `success_max_return_code` (default: 0): job succeeds if max step return code <= this
- `warning_max_return_code` (default: 1): job warns if max step return code <= this
- `step_exceptions` (array, optional): override rules for specific steps

#### Example `step_exceptions`:

```json
"step_exceptions": [
  {
    "step_name": "cleanup",
    "on_return_code": [2, 3],
    "action": "warn"
  }
]
```

---

## `retry_policy` (object, optional)

Job-level retry configuration.

### Fields:

- `max_attempts`: integer > 0
- `delay_seconds`: delay before retry
- `backoff_factor`: multiplier for increasing delay
- `retry_on`: array of return codes to retry on

---

## `log_settings` (object, optional)

Logging setup for the entire job.

### Fields:

- `stdout`: file path for capturing standard output
- `stderr`: file path for capturing standard error
- `rotation`: log rotation config:
  - `max_size_mb`
  - `max_files`
- `destination`: `file`, `event_log`, or `none`

---

## `steps` (array, required)

List of steps to be executed.

### Common Step Fields:

- `name` (string, required)
- `description` (string, optional)
- `path` (required): full Windows path to script
- `args` (array): arguments to pass to the script
- `working_directory`: override working dir
- `run_as_user`: override user
- `run_if_previous`: shortcut for common conditions (`success`, `failure`, `any`)

### Advanced: `condition` (optional)

Powerful logic for controlling whether a step runs.

#### Example:

```json
"condition": {
  "operator": "AND",
  "operands": [
    {
      "type": "all_previous",
      "comparison": "<=",
      "value": 0
    },
    {
      "type": "step",
      "step_name": "step1",
      "comparison": ">",
      "value": 1
    }
  ]
}
```

### `retry_policy` (object, optional)

Same structure as job-level retry policy, but applies to the step.

### `log_settings` (object, optional)

Same as job-level logging, applies per step.

---

## External Reference

You may refer to the full schema file at:

```
docs/schemas/job-spec.schema.json
```

Or view schema documentation online (when published):

```
https://example.com/job-schema-docs
```

---

For further assistance, please contact the platform engineering team.

