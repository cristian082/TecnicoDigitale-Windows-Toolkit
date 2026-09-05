$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'modules\TechnicianTools.ps1')
Show-TDTTechnicianTools
