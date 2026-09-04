function Get-TDTVersionInfo {
    [CmdletBinding()]
    param([string]$Root = (Split-Path -Parent $PSScriptRoot))

    $versionPath = Join-Path $Root 'VERSION.json'
    if (-not (Test-Path -LiteralPath $versionPath)) {
        return [pscustomobject]@{
            Version = '0.0.0'
            Status  = 'unknown'
            Build   = 'unknown'
        }
    }

    $data = Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json
    $build = 'source'

    # Se il Toolkit e' in un clone Git, usa il commit corrente come Build ID.
    try {
        $git = Get-Command git.exe -ErrorAction SilentlyContinue
        if (-not $git) { $git = Get-Command git -ErrorAction SilentlyContinue }
        if ($git) {
            $sha = (& $git.Source -C $Root rev-parse --short=8 HEAD 2>$null | Select-Object -First 1)
            if ($LASTEXITCODE -eq 0 -and $sha) { $build = ([string]$sha).Trim() }
        }
    }
    catch {
        $build = 'source'
    }

    [pscustomobject]@{
        Version = [string]$data.version
        Status  = [string]$data.status
        Build   = $build
    }
}

function Write-TDTVersionBanner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$VersionInfo,
        [string]$Prefix = 'TecnicoDigitale Windows Toolkit'
    )

    Write-Host ("{0} v{1} - Build {2} [{3}]" -f $Prefix, $VersionInfo.Version, $VersionInfo.Build, $VersionInfo.Status) -ForegroundColor Cyan
}
