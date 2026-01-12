<#
.SYNOPSIS
    Specops Password Policy (SPP) and Breached Password Protection (BPP) Health Check Script.

.DESCRIPTION
    This script verifies network connectivity to the required endpoints for SPP Admin Tools, 
    BPP Express, and BPP Complete (Arbiter Servers) as defined in the allowlist requirements.

.NOTES
    Context: Active Directory Environment
#>

param(
    [string[]]$ArbiterServers = @() # Optional list of Arbiter server hostnames
)

$ErrorActionPreference = "SilentlyContinue"

# Define requirements
$endpoints = @(
    @{ 
        URL         = "https://breach-protection.specopssoft.com"
        Port        = 443
        Description = "SPP/BPP Web Endpoint"
    },
    @{ 
        URL         = "https://download.specopssoft.com"
        Port        = 443
        Description = "SPP Download Endpoint"
    },
    @{ 
        URL         = "https://r3.c.lencr.org"
        Port        = 443
        Description = "Let's Encrypt CRL (HTTPS - Representative 1 for *.c.lencr.org)"
        TestHost    = "r3.c.lencr.org"
    },
    @{ 
        URL         = "http://r11.c.lencr.org"
        Port        = 80
        Description = "Let's Encrypt CRL (HTTP - Representative 2 for *.c.lencr.org)"
        TestHost    = "r11.c.lencr.org"
    },
    @{ 
        URL         = "https://crl.godaddy.com"
        Port        = 443
        Description = "GoDaddy CRL (HTTPS)"
    },
    @{ c:\Users\administrator.TN\AppData\Local\Packages\MicrosoftWindows.Client.Core_cw5n1h2txyewy\TempState\ScreenClip\ { E62BA364-DE82 - 40AE-8E47-020ECBF2BADB }.png
        URL = "http://crl.godaddy.com"
        Port = 80
        Description = "GoDaddy CRL (HTTP)"
    }
)

function Write-Header {
    param($Text)
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

function Test-EndpointConnectivity {
    param($Endpoint)
    
    $uri = [System.Uri]$Endpoint.URL
    $hostName = if ($Endpoint.TestHost) { $Endpoint.TestHost } else { $uri.Host }
    $port = $Endpoint.Port
    
    Write-Host "Testing $($Endpoint.Description)..." -ForegroundColor Gray
    Write-Host "  Target: $hostName on port $port" -ForegroundColor Gray
    
    # DNS Check
    try {
        $dns = [System.Net.Dns]::GetHostAddresses($hostName)
        $dnsStatus = "OK"
    }
    catch {
        $dnsStatus = "FAIL"
    }

    # TCP Check
    $tcpTest = Test-NetConnection -ComputerName $hostName -Port $port -InformationLevel Quiet
    
    # Web Request Check (if port 443 or 80)
    $webStatus = "N/A"
    if ($tcpTest) {
        try {
            $response = Invoke-WebRequest -Uri $Endpoint.URL -Method Head -TimeoutSec 5 -UseBasicParsing
            $webStatus = "OK ($($response.StatusCode))"
        }
        catch {
            $webStatus = "FAIL ($($_.Exception.Message))"
        }
    }

    if ($tcpTest) {
        Write-Host "SUCCESS" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Host "  [!] DIAGNOSTIC DETAILS:" -ForegroundColor Red
        Write-Host "  - DNS Resolution: $dnsStatus" -ForegroundColor Yellow
        Write-Host "  - TCP Port ${port}: FAILED (Connection timed out or blocked)" -ForegroundColor Yellow
        Write-Host "  - Web Response: $webStatus" -ForegroundColor Yellow
        return $false
    }
}

function Test-DeepCRL {
    param($Url)
    
    Write-Host "Performing Deep CRL Validation for $Url..." -ForegroundColor Cyan
    $tempCert = [System.IO.Path]::GetTempFileName() + ".cer"
    
    try {
        # Connect to the site and grab the certificate
        Write-Host "  - Fetching remote certificate... " -NoNewline
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $req = [Net.HttpWebRequest]::Create($Url)
        $req.Method = "GET" # Use GET for better compatibility
        $req.Timeout = 5000
        
        try {
            $response = $req.GetResponse()
        }
        catch [Net.WebException] {
            # Even if 404, we might have the certificate in the request's ServicePoint
            $response = $_.Exception.Response
        }
        
        $cert = $req.ServicePoint.Certificate
        if (-not $cert) {
            Write-Host "FAILED (No certificate returned)" -ForegroundColor Red
            return $false
        }
        
        # Export certificate to file
        $bytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        [System.IO.File]::WriteAllBytes($tempCert, $bytes)
        Write-Host "OK" -ForegroundColor Green
        
        # Run certutil to verify the chain and fetch CRLs
        Write-Host "  - Validating via OS Crypto API (certutil)... " -NoNewline
        $certutilOutput = certutil.exe -v -urlfetch -verify $tempCert 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $certutilOutput -match "Leaf certificate revocation check passed") {
            Write-Host "SUCCESS" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "FAILED" -ForegroundColor Red
            Write-Host "    [!] OS was unable to verify CRLs for this certificate." -ForegroundColor Yellow
            Write-Host "    [!] This often indicates Proxy or Firewall interference with Windows Crypto Services." -ForegroundColor Yellow
            # Show a snippet of the error
            $errLine = $certutilOutput | Where-Object { $_ -match "Error" -or $_ -match "fail" } | Select-Object -First 2
            if ($errLine) { Write-Host "    Reason: $errLine" -ForegroundColor Gray }
            return $false
        }
    }
    catch {
        Write-Host "FAILED ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
    finally {
        if (Test-Path $tempCert) { Remove-Item $tempCert -Force }
    }
}

# Main Execution
Clear-Host
Write-Host "Specops Password Policy Health Check" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Date: $(Get-Date)"
Write-Host "Machine: $($env:COMPUTERNAME)"
Write-Host "Domain: $($env:USERDNSDOMAIN)"

Write-Header "Connectivity Tests"
$allPassed = $true

foreach ($ep in $endpoints) {
    if (-not (Test-EndpointConnectivity -Endpoint $ep)) {
        $allPassed = $false
    }
}

Write-Header "Deep CRL Verification (OS/AD Level)"
$deepCrlHosts = @(
    "https://breach-protection.specopssoft.com",
    "https://r3.c.lencr.org",
    "https://r10.c.lencr.org",
    "https://r11.c.lencr.org",
    "https://x1.c.lencr.org",
    "https://x2.c.lencr.org",
    "https://e5.c.lencr.org",
    "https://e6.c.lencr.org"
)

foreach ($hostUrl in $deepCrlHosts) {
    if (-not (Test-DeepCRL -Url $hostUrl)) {
        $allPassed = $false
    }
}

Write-Header "Internal Connectivity Tests"
# 1. Test PDC Emulator (Port 4385)
try {
    Write-Host "Discovering PDC Emulator... " -NoNewline
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $pdc = $domain.PdcRoleOwner.Name
    Write-Host "FOUND ($pdc)" -ForegroundColor Green
    
    $pdcTest = @{ 
        URL         = "http://$pdc"
        Port        = 4385
        Description = "Admin Tool -> PDC Emulator"
        TestHost    = $pdc
    }
    if (-not (Test-EndpointConnectivity -Endpoint $pdcTest)) {
        $allPassed = $false
    }
}
catch {
    Write-Host "FAILED (Could not determine PDC Emulator)" -ForegroundColor Red
}

# 2. Test Arbiters (Port 4383)
$targetArbiters = @()
if ($ArbiterServers.Count -gt 0) {
    $targetArbiters = $ArbiterServers
}
else {
    # Attempt auto-discovery
    try {
        Write-Host "Attempting to auto-discover Arbiters via Specops module... " -NoNewline
        if (Get-Module -ListAvailable Specops.SpecopsPasswordPolicy) {
            Import-Module Specops.SpecopsPasswordPolicy -ErrorAction Stop
            # Force result to be an array even if only 1 item is returned
            $discovered = @(Get-PasswordPolicyArbiters | Select-Object -ExpandProperty Hostname)
            if ($discovered.Count -gt 0) {
                Write-Host "FOUND ($($discovered.Count) servers)" -ForegroundColor Green
                $targetArbiters = $discovered
            }
            else {
                Write-Host "NONE FOUND" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "SKIPPED (Module not found)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "FAILED ($($_.Exception.Message))" -ForegroundColor Red
    }
}

if ($targetArbiters.Count -gt 0) {
    foreach ($arbiter in $targetArbiters | Select-Object -Unique) {
        $arbiterTest = @{ 
            URL         = "http://$arbiter"
            Port        = 4383
            Description = "Admin Tool/DC -> Arbiter ($arbiter)"
            TestHost    = $arbiter
        }
        if (-not (Test-EndpointConnectivity -Endpoint $arbiterTest)) {
            $allPassed = $false
        }
    }
}
else {
    Write-Host "No Arbiter servers identified for testing." -ForegroundColor Yellow
    Write-Host "  Tip: Provide Arbiters via -ArbiterServers parameter or run on a machine with the Specops module installed." -ForegroundColor Gray
}

Write-Header "Summary"
if ($allPassed) {
    Write-Host "ALL CONNECTIVITY CHECKS PASSED" -ForegroundColor Green -BackgroundColor Black
    Write-Host "This machine meets the network requirements for SPP/BPP functionality."
}
else {
    Write-Host "SOME CHECKS FAILED" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Please check firewall allowlists and DNS settings for the failed endpoints above."
    Write-Host "Reference: spp_health_check_requirement.md"
}

Write-Host "`nPress any key to exit..."
# $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
