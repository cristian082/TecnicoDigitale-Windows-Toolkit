function Get-TDTLicenseStatusText {
    param([int]$Status)

    switch ($Status) {
        0 { 'Non licenziato' }
        1 { 'Licenziato' }
        2 { 'Periodo di tolleranza iniziale' }
        3 { 'Periodo di tolleranza aggiuntivo' }
        4 { 'Tolleranza non autentica' }
        5 { 'Periodo di notifica' }
        6 { 'Tolleranza estesa' }
        default { "Sconosciuto ($Status)" }
    }
}

function Get-TDTLicenseRisk {
    param(
        [string]$Description,
        [int]$LicenseStatus
    )

    if ($LicenseStatus -ne 1) { return 'NON ATTIVO' }
    if ($Description -match 'KMSCLIENT|VOLUME_KMSCLIENT') { return 'DA VERIFICARE' }
    return 'OK'
}

function Get-TDTWindowsLicenseInfo {
    $windowsAppId = '55c92734-d682-4d71-983e-d6ec3f16059f'
    $products = Get-CimInstance SoftwareLicensingProduct -ErrorAction SilentlyContinue |
        Where-Object { $_.ApplicationID -eq $windowsAppId -and $_.PartialProductKey } |
        Sort-Object LicenseStatus -Descending

    $product = $products | Select-Object -First 1
    $service = Get-CimInstance SoftwareLicensingService -ErrorAction SilentlyContinue

    if (-not $product) {
        return [pscustomobject]@{
            Name              = $null
            Description       = $null
            LicenseStatus     = 'Non rilevato'
            PartialProductKey = $null
            FirmwareKey       = if ($service) { $service.OA3xOriginalProductKey } else { $null }
            Assessment        = 'DA VERIFICARE'
        }
    }

    [pscustomobject]@{
        Name              = $product.Name
        Description       = $product.Description
        LicenseStatus     = Get-TDTLicenseStatusText -Status ([int]$product.LicenseStatus)
        PartialProductKey = $product.PartialProductKey
        FirmwareKey       = if ($service) { $service.OA3xOriginalProductKey } else { $null }
        Assessment        = Get-TDTLicenseRisk -Description $product.Description -LicenseStatus ([int]$product.LicenseStatus)
    }
}

function Get-TDTOfficeLicenseInfo {
    $officeAppId = '0ff1ce15-a989-479d-af46-f275c6370663'
    $products = Get-CimInstance SoftwareLicensingProduct -ErrorAction SilentlyContinue |
        Where-Object { $_.ApplicationID -eq $officeAppId -and $_.PartialProductKey }

    if (-not $products) { return @() }

    @($products | ForEach-Object {
        [pscustomobject]@{
            Name              = $_.Name
            Description       = $_.Description
            LicenseStatus     = Get-TDTLicenseStatusText -Status ([int]$_.LicenseStatus)
            PartialProductKey = $_.PartialProductKey
            Assessment        = Get-TDTLicenseRisk -Description $_.Description -LicenseStatus ([int]$_.LicenseStatus)
        }
    })
}

function Invoke-TDTDiagnostics {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Diagnostica] Check-up iniziale read-only' -ForegroundColor Cyan

    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1

    $systemDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($os.SystemDrive)'" -ErrorAction SilentlyContinue
    $physicalDisks = @()
    if (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) {
        $physicalDisks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{
                FriendlyName = $_.FriendlyName
                MediaType    = [string]$_.MediaType
                BusType      = [string]$_.BusType
                HealthStatus = [string]$_.HealthStatus
                SizeGB       = [math]::Round($_.Size / 1GB, 1)
            }
        })
    }

    $trim = $null
    try {
        $trimOutput = & fsutil behavior query DisableDeleteNotify 2>$null | Out-String
        $trim = if ($trimOutput -match 'NTFS DisableDeleteNotify\s*=\s*0') { 'Attivo' }
                elseif ($trimOutput -match 'NTFS DisableDeleteNotify\s*=\s*1') { 'Disattivo' }
                else { 'Non determinato' }
    } catch {
        $trim = 'Non determinato'
    }

    $startupItems = @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Select-Object Name, Command, Location, User)

    $defender = $null
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        try {
            $mp = Get-MpComputerStatus -ErrorAction Stop
            $defender = [pscustomobject]@{
                AntivirusEnabled          = $mp.AntivirusEnabled
                RealTimeProtectionEnabled = $mp.RealTimeProtectionEnabled
                AntispywareEnabled        = $mp.AntispywareEnabled
            }
        } catch {}
    }

    $firewallProfiles = @()
    if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
        $firewallProfiles = @(Get-NetFirewallProfile -ErrorAction SilentlyContinue | Select-Object Name, Enabled)
    }

    $uac = $null
    try {
        $uacValue = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop).EnableLUA
        $uac = if ($uacValue -eq 1) { 'Attivo' } else { 'Disattivo' }
    } catch {
        $uac = 'Non determinato'
    }

    $bitLocker = @()
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        try {
            $bitLocker = @(Get-BitLockerVolume -ErrorAction Stop | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod)
        } catch {}
    }

    $windowsLicense = Get-TDTWindowsLicenseInfo
    $officeLicenses = @(Get-TDTOfficeLicenseInfo)

    $report = [pscustomobject]@{
        GeneratedAt = (Get-Date).ToString('s')
        Computer = [pscustomobject]@{
            Manufacturer = $computer.Manufacturer
            Model        = $computer.Model
            BIOS         = $bios.SMBIOSBIOSVersion
        }
        Windows = [pscustomobject]@{
            Caption      = $os.Caption
            Version      = $os.Version
            BuildNumber  = $os.BuildNumber
            Architecture = $os.OSArchitecture
            InstallDate  = $os.InstallDate
        }
        CPU = [pscustomobject]@{
            Name                     = $cpu.Name
            Cores                    = $cpu.NumberOfCores
            LogicalProcessors        = $cpu.NumberOfLogicalProcessors
            MaxClockMHz              = $cpu.MaxClockSpeed
        }
        Memory = [pscustomobject]@{
            TotalGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
        }
        SystemDrive = if ($systemDrive) {
            [pscustomobject]@{
                Drive       = $systemDrive.DeviceID
                SizeGB      = [math]::Round($systemDrive.Size / 1GB, 1)
                FreeGB      = [math]::Round($systemDrive.FreeSpace / 1GB, 1)
                FreePercent = if ($systemDrive.Size -gt 0) { [math]::Round(($systemDrive.FreeSpace / $systemDrive.Size) * 100, 1) } else { 0 }
                TRIM        = $trim
            }
        } else { $null }
        PhysicalDisks = $physicalDisks
        Startup = [pscustomobject]@{
            Count = $startupItems.Count
            Items = $startupItems
        }
        Security = [pscustomobject]@{
            Defender = $defender
            Firewall = $firewallProfiles
            UAC      = $uac
            BitLocker = $bitLocker
        }
        Licensing = [pscustomobject]@{
            Windows = $windowsLicense
            Office  = $officeLicenses
        }
    }

    Write-Host ("  PC: {0} {1}" -f $report.Computer.Manufacturer, $report.Computer.Model)
    Write-Host ("  Windows: {0} - build {1}" -f $report.Windows.Caption, $report.Windows.BuildNumber)
    Write-Host ("  CPU: {0}" -f $report.CPU.Name)
    Write-Host ("  RAM: {0} GB" -f $report.Memory.TotalGB)
    if ($report.SystemDrive) {
        Write-Host ("  Disco sistema: {0} GB, liberi {1} GB ({2}%), TRIM {3}" -f $report.SystemDrive.SizeGB, $report.SystemDrive.FreeGB, $report.SystemDrive.FreePercent, $report.SystemDrive.TRIM)
    }
    Write-Host ("  Programmi in avvio rilevati: {0}" -f $report.Startup.Count)
    Write-Host ("  UAC: {0}" -f $report.Security.UAC)
    Write-Host ("  Windows licenza: {0} - {1}" -f $windowsLicense.Assessment, $windowsLicense.LicenseStatus)
    if ($windowsLicense.Description) { Write-Host ("    Canale: {0}" -f $windowsLicense.Description) }
    if ($windowsLicense.PartialProductKey) { Write-Host ("    Product key: *****-{0}" -f $windowsLicense.PartialProductKey) }

    if ($officeLicenses.Count -eq 0) {
        Write-Host '  Office: nessuna licenza rilevata'
    } else {
        foreach ($office in $officeLicenses) {
            Write-Host ("  Office: {0} - {1} - {2}" -f $office.Name, $office.Assessment, $office.LicenseStatus)
            if ($office.Description) { Write-Host ("    Canale: {0}" -f $office.Description) }
            if ($office.PartialProductKey) { Write-Host ("    Product key: *****-{0}" -f $office.PartialProductKey) }
        }
    }

    if ($Config.SaveJsonReport) {
        $root = Split-Path -Parent $PSScriptRoot
        $reportDir = Join-Path $root 'reports'
        if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir | Out-Null }
        $reportPath = Join-Path $reportDir ("Checkup-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date))
        $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
        Write-Host "  Report JSON: $reportPath"
    }

    return $report
}
