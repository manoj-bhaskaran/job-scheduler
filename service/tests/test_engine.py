# Licensed under the Apache License, Version 2.0 (the "License");

import os
import sys
import tempfile
import pytest
from unittest import mock
from service.src import engine


def test_log_windows_event_fallback(capfd):
    with mock.patch("win32evtlogutil.ReportEvent", side_effect=Exception("Log failure")):
        engine.log_windows_event("Test Message")
        captured = capfd.readouterr()
        assert "Fallback - Failed to write to Windows Event Log" in captured.err


def test_load_engine_config_env_not_set(monkeypatch):
    monkeypatch.delenv("JOB_SCHEDULER_CONFIG", raising=False)
    with pytest.raises(SystemExit):
        engine.load_engine_config()


def test_load_engine_config_file_missing(monkeypatch):
    monkeypatch.setenv("JOB_SCHEDULER_CONFIG", "nonexistent_file.yaml")
    with pytest.raises(SystemExit):
        engine.load_engine_config()


def test_load_engine_config_invalid_yaml(monkeypatch):
    with tempfile.NamedTemporaryFile(mode="w", delete=False) as tmp:
        tmp.write("invalid: [this is not: yaml")
        tmp_path = tmp.name

    monkeypatch.setenv("JOB_SCHEDULER_CONFIG", tmp_path)
    with pytest.raises(SystemExit):
        engine.load_engine_config()

    os.remove(tmp_path)


def test_stop_scheduler_changes_running_flag():
    engine.running = True
    engine.stop_scheduler(None, None)
    assert engine.running is False


def test_scheduler_loop_dispatches_job(monkeypatch):
    import threading
    import time
    from datetime import datetime

    now = datetime.now().replace(second=0, microsecond=0)
    job = {
        "name": "test-job",
        "trigger": {"type": "time", "schedule": now.strftime("%H:%M")},
        "steps": [{"name": "step1", "command": "echo Hello"}]
    }

    monkeypatch.setattr(engine, "load_jobs", lambda _: [job])

    dispatched = threading.Event()

    def mock_dispatch(job_arg):
        assert job_arg["name"] == "test-job"
        dispatched.set()

    monkeypatch.setattr(engine, "dispatch_job", mock_dispatch)
    monkeypatch.setattr(time, "sleep", lambda _: setattr(engine, "running", False))

    engine.running = True
    engine.scheduler_loop({"job_config_dir": "unused"})
    assert dispatched.is_set()
