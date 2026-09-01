function Invoke-TDTPrivacy {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Privacy] Applicazione impostazioni conservative'

    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    if (-not (Test-Path $cdm)) { New-Item -Path $cdm -Force | Out-Null }

    $values = @{
        'SystemPaneSuggestionsEnabled' = 0
        'SubscribedContent-338388Enabled' = 0
        'SubscribedContent-338389Enabled' = 0
        'SubscribedContent-353694Enabled' = 0
        'SubscribedContent-353696Enabled' = 0
    }

    foreach ($name in $values.Keys) {
        if ($PSCmdlet.ShouldProcess("$cdm\$name", 'Disabilitare suggerimenti/promozioni Windows')) {
            New-ItemProperty -Path $cdm -Name $name -PropertyType DWord -Value $values[$name] -Force | Out-Null
        }
    }

    if ($Config.DisableAdvertisingId) {
        $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
        if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }
        if ($PSCmdlet.ShouldProcess($adv, 'Disabilitare ID pubblicitario per utente')) {
            New-ItemProperty -Path $adv -Name Enabled -PropertyType DWord -Value 0 -Force | Out-Null
        }
    }
}
