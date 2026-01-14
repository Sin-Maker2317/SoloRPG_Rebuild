# Rojo dev helper

Use the provided scripts to always start Rojo on the project's standard dev port (34873).

PowerShell:

```powershell
./scripts/start_rojo_34873.ps1
```

Batch (Windows):

```bat
scripts\start_rojo_34873.bat
```

If you prefer to start `rojo` manually, run:

```powershell
rojo serve --port 34873
```

In Roblox Studio, open the Rojo plugin and connect to `127.0.0.1:34873`.
