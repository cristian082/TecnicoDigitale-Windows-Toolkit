function Set-TDTRegistryDword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
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

        $loadedPath = "Registry::HKEY_USERS\$sid"
        if (Test-Path $loadedPath) {
            & $Action $loadedPath
            continue
        }

        $tempName = "TDT_$([guid]::NewGuid().ToString('N'))"
        $tempPath = "Registry::HKEY_USERS\$tempName"
        & reg.exe load "HKU\$tempName" "$ntUser" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            try { & $Action $tempPath }
            finally {
                [gc]::Collect(); [gc]::WaitForPendingFinalizers()
                & reg.exe unload "HKU\$tempName" | Out-Null
            }
        }
    }

    if ($IncludeDefaultProfile) {
        $defaultNtUser = Join-Path $env:SystemDrive 'Users\Default\NTUSER.DAT'
        if (Test-Path $defaultNtUser) {
            $tempName = "TDT_Default_$([guid]::NewGuid().ToString('N'))"
            $tempPath = "Registry::HKEY_USERS\$tempName"
            & reg.exe load "HKU\$tempName" "$defaultNtUser" | Out-Null
            if ($LASTEXITCODE -eq 0) {
                try { & $Action $tempPath }
                finally {
                    [gc]::Collect(); [gc]::WaitForPendingFinalizers()
                    & reg.exe unload "HKU\$tempName" | Out-Null
                }
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
        Set-TDTRegistryDword -Path "HKCU:\$RelativePath" -Name $Name -Value $Value
        return
    }

    Invoke-TDTUserHiveAction -IncludeDefaultProfile -Action {
        param($HiveRoot)
        Set-TDTRegistryDword -Path "$HiveRoot\$RelativePath" -Name $Name -Value $Value
    }
}
