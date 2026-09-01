function Invoke-TDTDebloat {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Debloat] Rimozione selettiva app preinstallate'

    foreach ($package in $Config.RemovePackages) {
        $apps = Get-AppxPackage -Name $package -ErrorAction SilentlyContinue
        foreach ($app in $apps) {
            if ($PSCmdlet.ShouldProcess($app.Name, 'Rimuovere app per utente corrente')) {
                try {
                    Remove-AppxPackage -Package $app.PackageFullName -ErrorAction Stop
                } catch {
                    Write-Warning "Impossibile rimuovere $($app.Name): $($_.Exception.Message)"
                }
            }
        }
    }
}
