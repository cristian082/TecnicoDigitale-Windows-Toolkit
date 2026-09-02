function Test-TDTWingetPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)

    $listOutput = & winget list --id $Id --exact --accept-source-agreements 2>$null | Out-String
    return ($LASTEXITCODE -eq 0 -and $listOutput -match [regex]::Escape($Id))
}

function Install-TDTChromeOfficial {
    [CmdletBinding()]
    param()

    Write-Host '[Software] Chrome: uso fallback installer ufficiale Google...' -ForegroundColor Yellow

    $installer = Join-Path $env:TEMP 'TDT-GoogleChromeStandaloneEnterprise64.msi'
    $url = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'

    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -ErrorAction Stop
        $process = Start-Process msiexec.exe -ArgumentList @('/i', ('"{0}"' -f $installer), '/qn', '/norestart') -Wait -PassThru

        if ($process.ExitCode -notin @(0, 3010)) {
            throw "msiexec ha restituito il codice $($process.ExitCode)."
        }

        if (Test-TDTWingetPackageInstalled -Id 'Google.Chrome') {
            Write-Host '[Software] Google.Chrome installato correttamente tramite installer ufficiale.' -ForegroundColor Green
            return $true
        }

        $chromePaths = @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        )
        if ($chromePaths | Where-Object { $_ -and (Test-Path $_) }) {
            Write-Host '[Software] Google Chrome installato correttamente tramite installer ufficiale.' -ForegroundColor Green
            return $true
        }

        throw 'Installazione completata ma Chrome non e stato rilevato.'
    }
    catch {
        Write-Warning "Fallback ufficiale Google Chrome non riuscito: $($_.Exception.Message)"
        return $false
    }
    finally {
        Remove-Item $installer -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-TDTSoftware {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Software] Installazione software via winget'
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Write-Warning 'winget non disponibile. Modulo Software saltato.'
        return
    }

    & winget source update --accept-source-agreements 2>$null | Out-Null

    foreach ($id in $Config.WingetPackages) {
        if (-not $PSCmdlet.ShouldProcess($id, 'Installare o aggiornare pacchetto winget')) { continue }

        if (Test-TDTWingetPackageInstalled -Id $id) {
            Write-Host "[Software] $id gia installato. Verifica aggiornamenti..."
            & winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements
            $code = $LASTEXITCODE

            if ($code -eq 0) {
                Write-Host "[Software] $id aggiornato o gia alla versione piu recente."
            }
            elseif (Test-TDTWingetPackageInstalled -Id $id) {
                Write-Host "[Software] $id presente; nessun intervento necessario."
            }
            else {
                Write-Warning "Impossibile verificare/aggiornare $id (codice winget $code)."
            }
            continue
        }

        Write-Host "[Software] Installazione $id..."
        & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
        $code = $LASTEXITCODE

        if ($code -eq 0) {
            Write-Host "[Software] $id installato correttamente."
            continue
        }

        if ($id -eq 'Google.Chrome') {
            Write-Warning "Installazione winget di Google.Chrome non riuscita (codice $code). Non riscarico lo stesso pacchetto: provo l installer ufficiale Google."
            [void](Install-TDTChromeOfficial)
            continue
        }

        Write-Warning "Prima installazione di $id non riuscita (codice $code). Aggiorno le sorgenti e ritento una volta."
        & winget source update --accept-source-agreements 2>$null | Out-Null
        & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
        $code = $LASTEXITCODE

        if ($code -eq 0) {
            Write-Host "[Software] $id installato correttamente."
        }
        else {
            Write-Warning "Installazione di $id non riuscita dopo il secondo tentativo (codice winget $code)."
        }
    }
}
