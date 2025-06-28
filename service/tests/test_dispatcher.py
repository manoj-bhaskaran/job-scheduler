import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from service.src.dispatcher import dispatch_job

def test_dispatch_job_logs(caplog):
    job = {
        "name": "SampleJob",
        "steps": [
            {"name": "Step1", "command": "echo 'hello'"},
            {"name": "Step2", "command": "echo 'world'"}
        ]
    }
    with caplog.at_level("INFO", logger="scheduler.dispatcher"):
        dispatch_job(job)

    assert "Executing job 'SampleJob'" in caplog.text
    assert "Step: Step1" in caplog.text
    assert "Step: Step2" in caplog.text
