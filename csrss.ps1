function Delete-ShadowCopies {
    try {
        Write-Host "Deleting all shadow copies..." -ForegroundColor Yellow
        Start-Process -FilePath "vssadmin" -ArgumentList "delete shadows /all /quiet" -NoNewWindow -Wait
        Write-Host "All shadow copies deleted successfully." -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while deleting shadow copies: $_" -ForegroundColor Red
    }
}

Delete-ShadowCopies
