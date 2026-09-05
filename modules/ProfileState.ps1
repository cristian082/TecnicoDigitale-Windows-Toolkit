function Get-TDTProfileStatePath {
    param([Parameter(Mandatory)][string]$Root)
    return (Join-Path (Join-Path $Root 'backups') 'ProfileState.json')
}

function Get-TDTRegistryValueSnapshot {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Name)
    $exists = $false; $value = $null; $kind = $null
    if (Test-Path $Path) {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($key.GetValueNames() -contains $Name) {
            $exists = $true
            $value = $key.GetValue($Name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $kind = [string]$key.GetValueKind($Name)
        }
    }
    return [pscustomobject]@{ Path=$Path; Name=$Name; ValueExisted=$exists; Kind=$kind; Value=$value }
}

function Save-TDTProfileState {
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)]$State)
    $path = Get-TDTProfileStatePath -Root $Root
    $dir = Split-Path -Parent $path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
}

function Get-TDTProfileState {
    param([Parameter(Mandatory)][string]$Root)
    $path = Get-TDTProfileStatePath -Root $Root
    if (-not (Test-Path $path)) { return [pscustomobject]@{ SchemaVersion=1; Gaming=$null } }
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}

function Initialize-TDTGamingOwnership {
    param([Parameter(Mandatory)][string]$Root)
    $state = Get-TDTProfileState -Root $Root
    if ($null -ne $state.Gaming) { return }
    $entries = @(
        @{ Path='HKCU:\Software\Microsoft\GameBar'; Name='AutoGameModeEnabled'; AppliedValue=1 },
        @{ Path='HKCU:\Software\Microsoft\GameBar'; Name='AllowAutoGameMode'; AppliedValue=1 },
        @{ Path='HKCU:\System\GameConfigStore'; Name='GameDVR_Enabled'; AppliedValue=0 }
    )
    $saved = @()
    foreach ($item in $entries) {
        $snap = Get-TDTRegistryValueSnapshot -Path $item.Path -Name $item.Name
        $saved += [pscustomobject]@{ Path=$snap.Path; Name=$snap.Name; ValueExisted=$snap.ValueExisted; Kind=$snap.Kind; Value=$snap.Value; AppliedValue=$item.AppliedValue }
    }
    $state.Gaming = $saved
    Save-TDTProfileState -Root $Root -State $state
}

function Restore-TDTGamingOwnership {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)][string]$Root)
    $state = Get-TDTProfileState -Root $Root
    if ($null -eq $state.Gaming) { return }
    Write-Host '[Preset] Uscita da Gaming: ripristino delle sole impostazioni possedute dal Toolkit' -ForegroundColor DarkGray
    if ($WhatIfPreference) {
        foreach ($entry in @($state.Gaming)) { [void]$PSCmdlet.ShouldProcess("$($entry.Path)\$($entry.Name)",'Ripristinare stato precedente a Gaming') }
        return
    }
    $remaining = @()
    foreach ($entry in @($state.Gaming)) {
        try {
            $current = Get-TDTRegistryValueSnapshot -Path $entry.Path -Name $entry.Name
            if (-not $current.ValueExisted -or [int]$current.Value -ne [int]$entry.AppliedValue) {
                Write-Warning "[Preset] $($entry.Path)\$($entry.Name) e stato modificato dopo Gaming: non lo sovrascrivo."
                $remaining += $entry
                continue
            }
            if ($PSCmdlet.ShouldProcess("$($entry.Path)\$($entry.Name)",'Ripristinare stato precedente a Gaming')) {
                Add-TDTRegistryBackup -Path $entry.Path -Name $entry.Name
                if ($entry.ValueExisted) {
                    $propertyType = switch ([string]$entry.Kind) { 'DWord' {'DWord'} 'QWord' {'QWord'} 'Binary' {'Binary'} 'MultiString' {'MultiString'} 'ExpandString' {'ExpandString'} default {'String'} }
                    if (-not (Test-Path $entry.Path)) { New-Item -Path $entry.Path -Force | Out-Null }
                    New-ItemProperty -Path $entry.Path -Name $entry.Name -PropertyType $propertyType -Value $entry.Value -Force | Out-Null
                }
                elseif (Test-Path $entry.Path) { Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue }
            }
        }
        catch {
            Write-Warning "[Preset] Ripristino Gaming fallito per $($entry.Path)\$($entry.Name): $($_.Exception.Message)"
            $remaining += $entry
        }
    }
    $state.Gaming = if ($remaining.Count -gt 0) { $remaining } else { $null }
    Save-TDTProfileState -Root $Root -State $state
}
