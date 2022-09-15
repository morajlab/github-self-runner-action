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

function Install-Vagrant {
    Write-Host("Vagrant is not installed !");
    # TODO: install vagrant using Powershell
}

function Install-Runner {
    $command = {
        $runner_path = Join-Path $env:SystemDrive "actions-runner";

        New-Item -Path $runner_path -ItemType "directory" -Force;
        Set-Location -Path $runner_path;

        $request_uri = "https://api.github.com/repos/actions/runner/releases?per_page=1";
        $request_headers = @{
            "Accept"      = "application/vnd.github+json";
            "ContentType" = "application/json";
        };
        $request_asset_object = ((Invoke-WebRequest -Uri $request_uri -Headers $request_headers).Content |
            ConvertFrom-Json).assets |
        Where-Object { $_.name -like "*-win-x64-*" -and $_.name -notlike "*noexternals*" `
                -and $_.name -notlike "*noruntime*" -and $_.name -notlike "*trimmedpackages*" } |
        Select-Object -Property "browser_download_url", "name";

        Invoke-WebRequest -Uri $request_asset_object.browser_download_url -OutFile $request_asset_object.name;
        Add-Type -AssemblyName System.IO.Compression.FileSystem;
        [System.IO.Compression.ZipFile]::ExtractToDirectory((Join-Path "$PWD" $request_asset_object.name), "$PWD");
    }

    Invoke-PWSH -Command $command
}

if (-Not (Find-Program -ProgramName "vagrant")) {
    Install-Vagrant
}