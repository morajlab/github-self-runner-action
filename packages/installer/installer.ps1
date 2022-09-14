function Check_Program_Installed( $programName ) {
  $x86_check = ((Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall") |
  Where-Object { $_."Name" -like "*$programName*" } ).Length -gt 0;

  if(Test-Path 'HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
    $x64_check = ((Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
    Where-Object { $_."Name" -like "*$programName*" } ).Length -gt 0;
  }

  return $x86_check -or $x64_check;
}

# (Get-WmiObject Win32_OperatingSystem).SystemDrive
