<#
.SYNOPSIS
    Caprazli FMI Auto-Launcher
.DESCRIPTION
    Automatically locates the latest R installation on Windows and executes the analysis pipeline.
#>

Write-Host ">>> [INIT] Looking for R installation..." -ForegroundColor Cyan

# 1. Find Rscript.exe automatically in Program Files
# We sort descending to grab the highest version number (e.g., R-4.3.1 over R-4.1.0)
$rScriptPath = Get-ChildItem -Path "C:\Program Files\R" -Filter "Rscript.exe" -Recurse -ErrorAction SilentlyContinue | 
               Sort-Object FullName -Descending | 
               Select-Object -First 1 -ExpandProperty FullName

if (-not $rScriptPath) {
    Write-Host ">>> [ERROR] Rscript.exe not found in C:\Program Files\R." -ForegroundColor Red
    Write-Host "    Please ensure R is installed in the default location."
    Exit
}

Write-Host ">>> [FOUND] Using R at: $rScriptPath" -ForegroundColor Green

# 2. Check if the Analysis Script exists
$scriptPath = "R\run_analysis.R"
if (-not (Test-Path $scriptPath)) {
    Write-Host ">>> [ERROR] Analysis script not found at: $scriptPath" -ForegroundColor Red
    Write-Host "    Did you save the file inside the 'R' folder?"
    Exit
}

# 3. Execute the Pipeline
Write-Host ">>> [EXEC] Starting Caprazli FMI Pipeline..." -ForegroundColor Cyan
& $rScriptPath $scriptPath

# 4. Finish
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n>>> [SUCCESS] Analysis complete. Check the 'output' folder." -ForegroundColor Green
} else {
    Write-Host "`n>>> [FAIL] The R script encountered an error." -ForegroundColor Red
}

# Pause so the window doesn't close immediately
Read-Host -Prompt "Press Enter to exit"