function Set-TDTRegistryString {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    try {
        if (Get-Command Add-TDTRegistryBackup -ErrorAction SilentlyContinue) {
            Add-TDTRegistryBackup -Path $Path -Name $Name
        }
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Impossibile modificare $Path\$Name : $($_.Exception.Message)"
        return $false
    }
}

function Invoke-TDTVisualEffects {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Visual] Alleggerimento effetti visivi conservativo' -ForegroundColor Cyan

    # VISUAL-001 - Evita l'animazione di minimizzazione/massimizzazione delle finestre.
    # Non usa il preset globale "Prestazioni migliori" e non modifica font, miniature, ombre o trasparenze.
    if ($Config.DisableWindowMinMaxAnimation) {
        $path = 'HKCU:\Control Panel\Desktop\WindowMetrics'
        if ($PSCmdlet.ShouldProcess("$path\MinAnimate", 'Disattivare animazione minimizza/massimizza')) {
            [void](Set-TDTRegistryString -Path $path -Name 'MinAnimate' -Value '0')
        }
    }

    # VISUAL-002 - Disattiva solo le animazioni della barra delle applicazioni.
    # Evitiamo volutamente UserPreferencesMask: e un bitmask cumulativo che rischierebbe di alterare
    # effetti non richiesti e preferenze del cliente.
    if ($Config.DisableTaskbarAnimations) {
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        if ($PSCmdlet.ShouldProcess("$path\TaskbarAnimations", 'Disattivare animazioni barra delle applicazioni')) {
            [void](Set-TDTRegistryDword -Path $path -Name 'TaskbarAnimations' -Value 0)
        }
    }

    # VISUAL-003 - Riduce il ritardo di apertura dei menu senza azzerarlo.
    if ($null -ne $Config.MenuShowDelayMs) {
        $delay = [int]$Config.MenuShowDelayMs
        if ($delay -lt 0 -or $delay -gt 4000) { throw "MenuShowDelayMs non valido: $delay" }
        $path = 'HKCU:\Control Panel\Desktop'
        if ($PSCmdlet.ShouldProcess("$path\MenuShowDelay", "Impostare ritardo menu a $delay ms")) {
            [void](Set-TDTRegistryString -Path $path -Name 'MenuShowDelay' -Value ([string]$delay))
        }
    }

    Write-Host '[Visual] Conservati font smussati, miniature, ombre e trasparenze.' -ForegroundColor DarkGray
}
