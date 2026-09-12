# Top-level integration layer introduced in Build 10 and extended in Build 13.
# TechnicianTools.ps1 remains the complete Build 8 implementation.
# This file intentionally overrides only the top-level menu so additional tools
# can be added without rewriting or simplifying existing tools.

function Show-TDTTechnicianTools {
    param([Parameter(Mandatory)][string]$Root)

    if (-not (Test-TDTAdministrator)) {
        throw 'Gli Strumenti Tecnico richiedono privilegi amministrativi.'
    }

    do {
        Write-Host "`n=================================================="
        Write-Host ' TECNICO DIGITALE - STRUMENTI TECNICI' -ForegroundColor Cyan
        Write-Host '=================================================='
        Write-Host ' [1]  Rete'
        Write-Host ' [2]  Windows Update'
        Write-Host ' [3]  Integrita Windows - DISM / SFC'
        Write-Host ' [4]  Dischi / SMART / CHKDSK'
        Write-Host ' [5]  Stampanti'
        Write-Host ' [6]  Servizi'
        Write-Host ' [7]  Driver / dispositivi'
        Write-Host ' [8]  Avvio automatico (read-only)'
        Write-Host ' [9]  Eventi Windows recenti'
        Write-Host ' [10] BitLocker (read-only)'
        Write-Host ' [11] Spazio disco / TEMP (read-only)'
        Write-Host ' [12] Triage processi sospetti (read-only)'
        Write-Host ' [13] Comandi del tecnico - catalogo offline' -ForegroundColor Yellow
        Write-Host ' [14] Ibernazione e hiberfil.sys' -ForegroundColor Yellow
        Write-Host ' [15] Password e backup Wi-Fi' -ForegroundColor Yellow
        Write-Host ' [16] Ripristino sessione Blocco note' -ForegroundColor Yellow
        Write-Host ' [0]  Torna al menu principale'

        $c = Read-Host 'Scelta'
        try {
            switch ($c) {
                '1'  { Show-TDTNetworkTools }
                '2'  { Show-TDTWindowsUpdateTools }
                '3'  { Show-TDTWindowsRepairTools }
                '4'  { Show-TDTDiskTools }
                '5'  { Show-TDTPrinterTools }
                '6'  { Show-TDTServiceTools }
                '7'  { Show-TDTDriverTools }
                '8'  { Get-TDTStartupItems; Wait-TDTMenu }
                '9'  { Get-TDTRecentErrors; Wait-TDTMenu }
                '10' { Get-TDTBitLockerStatus; Wait-TDTMenu }
                '11' { Get-TDTDiskSpaceReport; Wait-TDTMenu }
                '12' { Get-TDTProcessTriage | Out-Null; Wait-TDTMenu }
                '13' { Show-TDTCommandReference -Root $Root }
                '14' { Show-TDTHibernationTools }
                '15' { Show-TDTWiFiCredentialTools }
                '16' { Show-TDTNotepadSessionTools }
                '0'  { return }
                default { Write-Warning 'Scelta non valida.' }
            }
        }
        catch {
            Write-Warning $_.Exception.Message
            Wait-TDTMenu
        }
    } while ($true)
}
