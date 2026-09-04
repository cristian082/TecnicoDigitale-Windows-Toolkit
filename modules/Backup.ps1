$script:TDTBackupSession = $null
$script:TDTBackupPath = $null

function Initialize-TDTBackupSession {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Preset
    )

    $backupDir = Join-Path $Root 'backups'
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }

    $id = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:TDTBackupPath = Join-Path $backupDir ("Session-$id.json")
    $script:TDTBackupSession = [ordered]@{
        SchemaVersion = 1
        SessionId     = $id
        CreatedAt     = (Get-Date).ToString('s')
        ComputerName  = $env:COMPUTERNAME
        UserName      = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        Preset        = $Preset
        Completed     = $false
        Registry      = @()
    }

    Save-TDTBackupSession
    Write-Host "[Backup] Sessione Undo: $script:TDTBackupPath" -ForegroundColor Cyan
}

function Save-TDTBackupSession {
    if (-not $script:TDTBackupSession -or -not $script:TDTBackupPath) { return }
    $script:TDTBackupSession | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $script:TDTBackupPath -Encoding UTF8
}

function Add-TDTRegistryBackup {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    if (-not $script:TDTBackupSession) { return }

    $alreadySaved = @($script:TDTBackupSession.Registry | Where-Object { $_.Path -eq $Path -and $_.Name -eq $Name }).Count -gt 0
    if ($alreadySaved) { return }

    $keyExisted = Test-Path $Path
    $valueExisted = $false
    $value = $null
    $kind = $null

    if ($keyExisted) {
        try {
            $key = Get-Item -LiteralPath $Path -ErrorAction Stop
            if ($key.GetValueNames() -contains $Name) {
                $valueExisted = $true
                $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                $kind = [string]$key.GetValueKind($Name)
            }
        }
        catch {
            Write-Warning "Backup registro non riuscito per $Path\$Name : $($_.Exception.Message)"
            throw
        }
    }

    $entry = [pscustomobject]@{
        Path         = $Path
        Name         = $Name
        KeyExisted   = $keyExisted
        ValueExisted = $valueExisted
        Kind         = $kind
        Value        = $value
    }
    $script:TDTBackupSession.Registry += $entry
    Save-TDTBackupSession
}

function Complete-TDTBackupSession {
    if (-not $script:TDTBackupSession) { return }
    $script:TDTBackupSession.Completed = $true
    $script:TDTBackupSession.CompletedAt = (Get-Date).ToString('s')
    Save-TDTBackupSession
}
