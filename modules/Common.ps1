function Set-TDTRegistryDword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Impossibile modificare $Path\$Name : $($_.Exception.Message)"
        return $false
    }
}

function Invoke-TDTUserHiveAction {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [switch]$IncludeDefaultProfile
    )

    $profileList = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
    $profiles = Get-ChildItem $profileList -ErrorAction SilentlyContinue | Where-Object {
        $_.PSChildName -match '^S-1-5-21-'
    }

    foreach ($profile in $profiles) {
        $sid = $profile.PSChildName
        $profilePath = (Get-ItemProperty $profile.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if (-not $profilePath) { continue }
        $profilePath = [Environment]::ExpandEnvironmentVariables($profilePath)
        $ntUser = Join-Path $profilePath 'NTUSER.DAT'
        if (-not (Test-Path $ntUser)) { continue }

        # If Windows already has the hive loaded, use it directly.
        $loadedPath = "Registry::HKEY_USERS\$sid"
        if (Test-Path $loadedPath) {
            try { & $Action $loadedPath }
            catch { Write-Warning "Profilo $profilePath saltato: $($_.Exception.Message)" }
            continue
        }

        # Offline profile: load NTUSER.DAT temporarily under HKU.
        $tempName = "TDT_$([guid]::NewGuid().ToString('N'))"
        $tempPath = "Registry::HKEY_USERS\$tempName"
        & reg.exe load "HKU\$tempName" "$ntUser" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Impossibile caricare il profilo offline $profilePath; viene saltato."
            continue
        }

        try {
            & $Action $tempPath
        }
        catch {
            Write-Warning "Profilo $profilePath saltato: $($_.Exception.Message)"
        }
        finally {
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            & reg.exe unload "HKU\$tempName" 2>$null | Out-Null
        }
    }

    if ($IncludeDefaultProfile) {
        $defaultNtUser = Join-Path $env:SystemDrive 'Users\Default\NTUSER.DAT'
        if (Test-Path $defaultNtUser) {
            $tempName = "TDT_Default_$([guid]::NewGuid().ToString('N'))"
            $tempPath = "Registry::HKEY_USERS\$tempName"
            & reg.exe load "HKU\$tempName" "$defaultNtUser" 2>$null | Out-Null

            if ($LASTEXITCODE -eq 0) {
                try {
                    & $Action $tempPath
                }
                catch {
                    Write-Warning "Profilo Default saltato: $($_.Exception.Message)"
                }
                finally {
                    [gc]::Collect()
                    [gc]::WaitForPendingFinalizers()
                    & reg.exe unload "HKU\$tempName" 2>$null | Out-Null
                }
            }
            else {
                Write-Warning 'Impossibile caricare il profilo Default; le impostazioni per i nuovi utenti vengono saltate.'
            }
        }
    }
}

function Set-TDTUserDword {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value,
        [bool]$AllUsers = $true
    )

    if (-not $AllUsers) {
        [void](Set-TDTRegistryDword -Path "HKCU:\$RelativePath" -Name $Name -Value $Value)
        return
    }

    Invoke-TDTUserHiveAction -IncludeDefaultProfile -Action {
        param($HiveRoot)
        [void](Set-TDTRegistryDword -Path "$HiveRoot\$RelativePath" -Name $Name -Value $Value)
    }
}
