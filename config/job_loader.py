# Licensed under the Apache License, Version 2.0 (the "License");

import os
import yaml

CONFIG_DIR = "config"


def load_jobs():
    jobs = []
    for file_name in os.listdir(CONFIG_DIR):
        if file_name.endswith(".yaml") or file_name.endswith(".yml"):
            with open(os.path.join(CONFIG_DIR, file_name), 'r') as f:
                job = yaml.safe_load(f)
                jobs.append(job)
    return jobs
