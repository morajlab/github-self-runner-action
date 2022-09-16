[CmdletBinding()]
param (
  [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
  [pscustomobject]
  $RunnerContext,
  [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
  [pscustomobject]
  $GitHubContext
)

process {
  Import-Module powershell-yaml

  function Invoke-GHWebRequest {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [string]
      $URI,
      [Parameter(Mandatory = $false)]
      [pscustomobject]
      $Headers,
      [Parameter(Mandatory = $false)]
      [string]
      $Token
    )
    
    $all_headers = @{
      "Accept" = "application/vnd.github+json";
    };

    if ($Headers -ne $null) {
      $all_headers += $Headers;
    }

    if ($Token -ne $null -and $Token -ne '') {
      $all_headers += @{ "Authorization" = "Bearer ${Token}" };
    }

    $response = Invoke-WebRequest -Uri $URI -Headers $all_headers;

    return @{
      Response      = $response;
      ContentObject = ($response.Content | ConvertFrom-Json);
    };
  }

  function Get-GHFileContent {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [string]
      $Repo,
      [Parameter(Mandatory = $false)]
      [string]
      $Path,
      [Parameter(Mandatory = $false)]
      [string]
      $Token
    )

    $request_uri = "https://api.github.com/repos/${Repo}/contents/${Path}";

    $file_content = (Invoke-GHWebRequest -URI $request_uri -Token $Token).ContentObject.content;
    $file_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($file_content));

    return $file_content;
  }

  function Get-GHWorkflowContent {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [string]
      $RunID,
      [Parameter(Mandatory = $true)]
      [string]
      $Repo,
      [Parameter(Mandatory = $false)]
      [string]
      $Token,
      [Parameter(Mandatory = $false)]
      [string]
      $Ref
    )

    $request_uri = "https://api.github.com/repos/${Repo}/actions/runs/${RunID}";
    $workflow_metadata = (Invoke-GHWebRequest -URI $request_uri -Token $Token).ContentObject;
    $path = $workflow_metadata.path;

    if ($Ref -ne $null -and $Ref -ne '') {
      $path += "?ref=${Ref}";
    }

    $content = ConvertFrom-Yaml (Get-GHFileContent -Repo $Repo -Token $Token -Path $path);
    
    return @{
      Metadata = $workflow_metadata;
      Content  = $content;
    };
  }

  $jobs_url = (Get-GHWorkflowContent -RunID $_.GitHubContext.run_id `
      -Repo $_.GitHubContext.repository -Ref $_.GitHubContext.ref).Metadata.jobs_url;
  
  (Invoke-GHWebRequest -URI $jobs_url).ContentObject.jobs | ForEach-Object {
    $_
  };
}
