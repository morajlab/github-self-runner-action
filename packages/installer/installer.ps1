function Check_Program_Installed($programName) {
    $x86_check = ((Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall") |
            Where-Object { $_.Name -like "*$programName*" }).Length -gt 0;

    if (Test-Path 'HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
        $x64_check = ((Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
                Where-Object { $_."Name" -like "*$programName*" } ).Length -gt 0;
    }

    return $x86_check -or $x64_check;
}

if (!(Check_Program_Installed("vagrant"))) {
    Write-Host("Vagrant is not installed !");
    # TODO: install vagrant using Powershell
}

$installRunnerCommand = {
    New-Item -Name "actions-runner" -ItemType "directory" -Force;
    Set-Location -Path "actions-runner";

    $runnerAssetObject = ((Invoke-WebRequest -Uri "https://api.github.com/repos/actions/runner/releases?per_page=1" -Headers @{ "Accept" = "application/vnd.github+json" } -ContentType "application/json").Content |
            ConvertFrom-Json).assets |
            Where-Object { $_.name -like "*-win-x64-*" -and $_.name -notlike "*noexternals*" -and $_.name -notlike "*noruntime*" -and $_.name -notlike "*trimmedpackages*" } |
            Select-Object -Property browser_download_url, name;

    Invoke-WebRequest -Uri $runnerAssetObject.browser_download_url -OutFile $runnerAssetObject.name;
    Add-Type -AssemblyName System.IO.Compression.FileSystem;
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\$($runnerAssetObject.name)", "$PWD");
}

pwsh -NoLogo -STA -NonInteractive -NoProfile -ExecutionPolicy Unrestricted -WorkingDirectory "${env:SystemDrive}\" -Command $installRunnerCommand
