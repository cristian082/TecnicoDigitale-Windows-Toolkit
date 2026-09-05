$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'modules\CommandReference.ps1')
. (Join-Path $root 'modules\TechnicianTools.ps1')
Show-TDTTechnicianTools -Root $root
