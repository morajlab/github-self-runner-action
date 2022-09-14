if (!(Get-Module -ListAvailable -Name "PSScriptAnalyzer")) {
  Install-Module -Name "PSScriptAnalyzer" -Scope CurrentUser -Force
}

Import-Module "PSScriptAnalyzer"

foreach($arg in $ARGS) {
  $content = Get-Content -Path $arg | Out-String | ForEach-Object { Invoke-Formatter -ScriptDefinition $_ }
  $content > $arg
}