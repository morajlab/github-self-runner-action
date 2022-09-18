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
