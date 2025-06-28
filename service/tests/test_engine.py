import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from service.src.engine import load_engine_config, should_run_now

def test_load_engine_config_reads_file(monkeypatch):
    import tempfile
    import yaml

    config = {"log_file": "logs/test.log", "job_config_dir": "config/jobs"}
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as f:
        yaml.dump(config, f)
        f.flush()
        monkeypatch.setenv("JOB_SCHEDULER_CONFIG", f.name)
        result = load_engine_config()
        assert result == config
    os.remove(f.name)

def test_should_run_now_true():
    from datetime import datetime
    job = {"trigger": {"type": "time", "schedule": "10:30"}}
    now = datetime.strptime("10:30", "%H:%M")
    assert should_run_now(job, now)

def test_should_run_now_false():
    from datetime import datetime
    job = {"trigger": {"type": "time", "schedule": "10:30"}}
    now = datetime.strptime("11:00", "%H:%M")
    assert not should_run_now(job, now)
