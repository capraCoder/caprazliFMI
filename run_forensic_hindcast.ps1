# ==============================================================================
# Run Forensic Hindcast Validation
# ==============================================================================
# Tests whether FMI predicts stock collapses
# ==============================================================================

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  FORENSIC HINDCAST VALIDATION — CAPRAZLI FMI" -ForegroundColor Cyan
Write-Host "  Testing: Does FMI predict stock collapses?" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Run the R script
& "C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe" "R\forensic_hindcast_validation.R"

Write-Host ""
Write-Host "Done. Check output\forensic_hindcast\ for results." -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
