function Get-MD5Hash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $StringContent
    )

    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider;
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding;
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($StringContent)))

    return $hash;
}

function Invoke-PWSH {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Command
    )

    pwsh -NoLogo -STA -NonInteractive -NoProfile -ExecutionPolicy Unrestricted -Command $Command
}

function Find-Program {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ProgramName
    )

    [string[]]$registry_paths = "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall";

    foreach ($path in $registry_paths) {
        if (Test-Path $path) {
            $result = ((Get-ChildItem $path) |
                Where-Object { $_.Name -like "*$ProgramName*" }).Length -gt 0;

            if ($result) {
                return $true;
            }
        }
    }

    return $false;
}
