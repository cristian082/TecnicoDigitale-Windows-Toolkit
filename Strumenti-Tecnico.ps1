$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load order is intentional: full Build 8 tools first, then the offline
# command reference and hibernation tools, then the small top-level menu override.
. (Join-Path $root 'modules\TechnicianTools.ps1')
. (Join-Path $root 'modules\CommandReference.ps1')
. (Join-Path $root 'modules\HibernationTools.ps1')
. (Join-Path $root 'modules\TechnicianToolsMenu.ps1')

Show-TDTTechnicianTools -Root $root
