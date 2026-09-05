function Set-TDTRegistryDword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    try {
        if (Get-Command Add-TDTRegistryBackup -ErrorAction SilentlyContinue) {
            Add-TDTRegistryBackup -Path $Path -Name $Name
        }
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Impossibile modificare $Path\$Name : $($_.Exception.Message)"
        return $false
    }
}

function Get-TDTDeterministicGuid {
    param([Parameter(Mandatory)][string]$Text)

    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $md5.ComputeHash($bytes)
        $guidBytes = New-Object byte[] 16
        [Array]::Copy($hash, $guidBytes, 16)
        return (New-Object Guid (,$guidBytes)).ToString('B')
    }
    finally {
        $md5.Dispose()
    }
}

function Get-TDTActiveSetupComponentPath {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Name
    )

    $componentGuid = Get-TDTDeterministicGuid -Text "$RelativePath|$Name"
    return "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$componentGuid"
}

function Register-TDTActiveSetupDword {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    # Active Setup esegue lo StubPath nel contesto di ogni utente al prossimo accesso.
    # In questo modo non forziamo la scrittura negli hive di profili non attivi/protetti.
    $componentPath = Get-TDTActiveSetupComponentPath -RelativePath $RelativePath -Name $Name
    if (-not (Test-Path $componentPath)) { New-Item -Path $componentPath -Force | Out-Null }

    $regPath = 'HKCU\' + $RelativePath.Replace(':','').Replace('/','\')
    $stubPath = "reg.exe add `"$regPath`" /v `"$Name`" /t REG_DWORD /d $Value /f"
    $now = Get-Date
    $version = "{0},{1},{2},{3}" -f $now.Year,$now.Month,$now.Day,([int]($now.ToString('HHmm')))

    New-ItemProperty -Path $componentPath -Name '(default)' -PropertyType String -Value "TecnicoDigitale - $Name" -Force | Out-Null
    New-ItemProperty -Path $componentPath -Name 'Version' -PropertyType String -Value $version -Force | Out-Null
    New-ItemProperty -Path $componentPath -Name 'IsInstalled' -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $componentPath -Name 'StubPath' -PropertyType String -Value $stubPath -Force | Out-Null
}

function Remove-TDTActiveSetupDword {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Name
    )

    $componentPath = Get-TDTActiveSetupComponentPath -RelativePath $RelativePath -Name $Name
    if (-not (Test-Path $componentPath)) { return $false }

    try {
        $label = (Get-ItemProperty -LiteralPath $componentPath -ErrorAction SilentlyContinue).'(default)'
        if ($label -and [string]$label -notlike 'TecnicoDigitale -*') {
            Write-Warning "Active Setup $componentPath non sembra appartenere al Toolkit: non lo rimuovo."
            return $false
        }
        Remove-Item -LiteralPath $componentPath -Recurse -Force -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Impossibile rimuovere Active Setup per $RelativePath\$Name : $($_.Exception.Message)"
        return $false
    }
}

function Set-TDTUserDword {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value,
        [bool]$AllUsers = $true
    )

    # Applica immediatamente all'utente che sta eseguendo il toolkit.
    [void](Set-TDTRegistryDword -Path "HKCU:\$RelativePath" -Name $Name -Value $Value)

    if ($AllUsers) {
        try {
            Register-TDTActiveSetupDword -RelativePath $RelativePath -Name $Name -Value $Value
        }
        catch {
            Write-Warning "Impossibile registrare Active Setup per $RelativePath\$Name : $($_.Exception.Message)"
        }
    }
}
