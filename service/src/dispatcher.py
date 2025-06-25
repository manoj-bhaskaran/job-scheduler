# Licensed under the Apache License, Version 2.0 (the "License");

import logging

logger = logging.getLogger("scheduler.dispatcher")


def dispatch_job(job):
    logger.info(f"Executing job '{job['name']}' with command: {job['steps']}")
    # Simulate actual dispatch
    for step in job.get('steps', []):
        logger.info(f"  -> Step: {step['name']}, Command: {step['command']}")
