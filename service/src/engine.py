
# Licensed under the Apache License, Version 2.0 (the "License");
"""
Scheduler Engine

This module implements the core loop of the job scheduler. It performs the following tasks:
1. Loads the engine configuration from a YAML file specified by the JOB_SCHEDULER_CONFIG environment variable.
2. Sets up logging to the configured log file.
3. Loads job definitions from the specified job configuration directory.
4. Runs a time-based loop to dispatch jobs whose triggers match the current time.
"""

import os
import sys
import time
import yaml
import signal
import logging
import threading
from datetime import datetime, timedelta
from service.dispatcher import dispatch_job
from config.job_loader import load_jobs
import win32evtlogutil
import win32evtlog


def log_windows_event(message, event_id=1001, category=1, event_type=win32evtlog.EVENTLOG_ERROR_TYPE):
    try:
        win32evtlogutil.ReportEvent(
            appName="JobScheduler",
            eventID=event_id,
            eventCategory=category,
            eventType=event_type,
            strings=[message],
            data=b''
        )
    except Exception as e:
        print(f"Fallback - Failed to write to Windows Event Log: {e}\n{message}", file=sys.stderr)


def load_engine_config():
    env_var = "JOB_SCHEDULER_CONFIG"
    config_path = os.environ.get(env_var)

    if not config_path:
        msg = f"Environment variable {env_var} not set."
        log_windows_event(msg)
        sys.exit(1)

    if not os.path.isfile(config_path):
        msg = f"Config file not found at {config_path}"
        log_windows_event(msg)
        sys.exit(1)

    try:
        with open(config_path, "r") as f:
            return yaml.safe_load(f)
    except Exception as e:
        msg = f"Failed to read or parse config file {config_path}: {e}"
        log_windows_event(msg)
        sys.exit(1)


def setup_logging(log_file):
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )


def should_run_now(job, current_time):
    if job['trigger']['type'] == 'time':
        cron = job['trigger']['schedule']
        return cron == current_time.strftime("%H:%M")
    return False


running = True

def stop_scheduler(signum, frame):
    global running
    logging.getLogger("scheduler.engine").info("Received shutdown signal.")
    running = False


def scheduler_loop(config):
    logger = logging.getLogger("scheduler.engine")
    logger.info("Starting scheduler loop")

    jobs = load_jobs(config['job_config_dir'])

    while running:
        now = datetime.now()
        for job in jobs:
            if should_run_now(job, now):
                logger.info(f"Dispatching job: {job['name']}")
                threading.Thread(target=dispatch_job, args=(job,), daemon=True).start()

        next_minute = (datetime.now() + timedelta(minutes=1)).replace(second=0, microsecond=0)
        sleep_seconds = (next_minute - datetime.now()).total_seconds()
        time.sleep(sleep_seconds)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, stop_scheduler)
    signal.signal(signal.SIGTERM, stop_scheduler)
    config = load_engine_config()
    setup_logging(config['log_file'])
    scheduler_loop(config)
