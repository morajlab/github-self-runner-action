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
  function Install-VagrantVM {
    # TODO: Install GitHub-hosted VMs
    vagrant init gusztavvargadr/windows-server
    vagrant up
  }

  function Invoke-GHJob {
    [CmdletBinding()]
    param (
      [Parameter(Mandatory = $true)]
      [pscustomobject]
      $Job
    )

    # Invoke vagrant module
  }

  $github_context = $_.GitHubContext;
  $jobs_url = (Get-GHWorkflowContent -RunID $github_context.run_id `
      -Repo $github_context.repository -Ref $github_context.ref).Metadata.jobs_url;

  (Invoke-GHWebRequest -URI $jobs_url).ContentObject.jobs | ForEach-Object {
    if ($_.name -ne $github_context.job -and $_.status -ne "completed") {
      Invoke-GHJob -Job $_;
      return;
    }
  };
}
