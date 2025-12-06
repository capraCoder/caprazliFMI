# ==============================================================================
# Run RAM Legacy Validation Candidates Script
# ==============================================================================
# Place this file in C:\Users\capra\caprazliFMI\
# ==============================================================================

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RAM Legacy FMI Validation Candidates" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run the R script
& "C:\Program Files\R\R-4.5.1\bin\x64\Rscript.exe" "R\RAM_validation_candidates.R"

Write-Host ""
Write-Host "Done. Check output\validation\ for results." -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
