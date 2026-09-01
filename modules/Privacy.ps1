function Invoke-TDTPrivacy {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Privacy] Applicazione impostazioni conservative'
    $allUsers = if ($null -ne $Config.PSObject.Properties['AllUsers']) { [bool]$Config.AllUsers } else { $true }

    $values = @{
        'SystemPaneSuggestionsEnabled' = 0
        'SubscribedContent-338388Enabled' = 0
        'SubscribedContent-338389Enabled' = 0
        'SubscribedContent-353694Enabled' = 0
        'SubscribedContent-353696Enabled' = 0
    }

    foreach ($name in $values.Keys) {
        if ($PSCmdlet.ShouldProcess("ContentDeliveryManager\$name", 'Disabilitare suggerimenti/promozioni Windows')) {
            Set-TDTUserDword -RelativePath 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name $name -Value $values[$name] -AllUsers $allUsers
        }
    }

    if ($Config.DisableAdvertisingId -and $PSCmdlet.ShouldProcess('AdvertisingInfo', 'Disabilitare ID pubblicitario')) {
        Set-TDTUserDword -RelativePath 'Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -AllUsers $allUsers
    }
}
