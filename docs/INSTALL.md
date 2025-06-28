# Job Scheduler Installation Guide

This document outlines the steps required to install and configure the Job Scheduler on a Windows system.

---

## 1. Prerequisites

- Python 3.8 or higher installed
- Git (optional, if cloning the repository)
- Administrator privileges (for setting environment variables and writing to Windows Event Log)

---

## 2. Clone or Download the Repository

```powershell
git clone https://github.com/manoj-bhaskaran/job-scheduler.git
cd job-scheduler
```

---

## 3. Set Up Virtual Environment

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## 4. Prepare Configuration Files

1. Create the engine config file:
   Example: `C:\job-scheduler\config\engine-config.yaml`

```yaml
log_file: C:\job-scheduler\logs\scheduler.log
job_config_dir: C:\job-scheduler\config\jobs
```

2. Create a `config\jobs\` directory and place job YAML files inside it.

---

## 5. Set Environment Variable

Set the `JOB_SCHEDULER_CONFIG` environment variable to the full path of your config file:

```powershell
[System.Environment]::SetEnvironmentVariable(
    "JOB_SCHEDULER_CONFIG",
    "C:\job-scheduler\config\engine-config.yaml",
    [System.EnvironmentVariableTarget]::Machine
)
```

---

## 6. Register Windows Event Log Source

> Required for logging scheduler errors to Windows Event Viewer.

```powershell
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\JobScheduler" -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\JobScheduler" `
    -Name "EventMessageFile" -Value "$($env:WINDIR)\System32\EventCreate.exe" -PropertyType "String"
```

**Note:** Run PowerShell as **Administrator** for this step.

---

## 7. Run the Scheduler

```powershell
.venv\Scripts\Activate.ps1
python service\engine.py
```

---

## 8. Verify Logs

- Scheduler logs: `C:\job-scheduler\logs\scheduler.log`
- Windows Event Log: Open **Event Viewer → Windows Logs → Application** and filter for **Source = JobScheduler**

---

## 9. Uninstallation (Manual)

- Remove environment variable:

```powershell
Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
    -Name 'JOB_SCHEDULER_CONFIG'
```

- Delete event source:

```powershell
Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\JobScheduler" -Recurse
```

---

## ✅ Checklist (Do Not Skip)

- [ ] Python virtual environment created
- [ ] `requirements.txt` installed
- [ ] `engine-config.yaml` created
- [ ] `JOB_SCHEDULER_CONFIG` environment variable set
- [ ] Event Log source `JobScheduler` registered
