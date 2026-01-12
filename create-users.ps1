<#
.SYNOPSIS
    Creates test users in specified Active Directory OUs.

.DESCRIPTION
    This script automates the creation of test Organizational Units (OUs) and users.
    It creates OUs (e.g., Sales, IT) if they don't exist and then populates them
    with a specified number of users following a naming convention (e.g., sales1, it1).

.PARAMETER OUNames
    An array of OU names to create and populate. Default is 'Sales', 'IT'.

.PARAMETER UsersPerOU
    The number of users to create in each OU. Default is 5.

.PARAMETER DomainSuffix
    The domain suffix for UPN and Email. Default is 'tn.com'.

.EXAMPLE
    .\create-users.ps1 -OUNames 'Sales', 'IT' -UsersPerOU 5 -DomainSuffix 'tn.com'
#>

param (
    [string]$ParentOU = 'Company',
    [string[]]$OUNames = @('Sales', 'IT'),
    [int]$UsersPerOU = 5,
    [string]$DomainSuffix = 'tn.com',
    [string]$DefaultPassword = 'SecurePass123!'
)

# Check if ActiveDirectory module is available
if (-not (Get-Module -ListAvailable ActiveDirectory)) {
    Write-Error "ActiveDirectory module not found. Please install RSAT-AD-PowerShell."
    return
}

Import-Module ActiveDirectory

# Get root DN
try {
    $rootDN = (Get-ADDomain).DistinguishedName
    Write-Host "Detected Root DN: $rootDN" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to connect to Active Directory. Ensure you are on a domain-joined machine with appropriate permissions."
    return
}

# Ensure Parent OU exists
$parentOUDN = "OU=$ParentOU,$rootDN"
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ParentOU'" -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Parent OU: $parentOUDN" -ForegroundColor Yellow
    New-ADOrganizationalUnit -Name $ParentOU -Path $rootDN -Description "Parent OU for test users" -ErrorAction Stop
}
else {
    Write-Host "Parent OU already exists: $parentOUDN" -ForegroundColor Green
}

$securePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

foreach ($ouName in $OUNames) {
    $ouDN = "OU=$ouName,$parentOUDN"
    
    # Create OU if it doesn't exist
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue)) {
        Write-Host "Creating OU: $ouDN" -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name $ouName -Path $parentOUDN -Description "Test OU for $ouName" -ErrorAction Stop
    }
    else {
        Write-Host "OU already exists: $ouDN" -ForegroundColor Green
    }

    # Create Users
    for ($i = 1; $i -le $UsersPerOU; $i++) {
        $samAccountName = "$($ouName.ToLower())$i"
        $displayName = "$ouName $i (Test)"
        $givenName = "$ouName$i"
        $surname = "Test"
        $upn = "$samAccountName@$DomainSuffix"
        $email = "$samAccountName@$DomainSuffix"
        $phoneNumber = "555-01$(Get-Random -Minimum 10 -Maximum 99)"

        # Check if user already exists
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue)) {
            Write-Host "Creating user: $samAccountName in $ouName with phone $phoneNumber" -ForegroundColor Cyan
            
            $userParams = @{
                Name                  = $samAccountName
                SamAccountName        = $samAccountName
                GivenName             = $givenName
                Surname               = $surname
                DisplayName           = $displayName
                UserPrincipalName     = $upn
                EmailAddress          = $email
                OfficePhone           = $phoneNumber
                Path                  = $ouDN
                AccountPassword       = $securePassword
                Enabled               = $true
                ChangePasswordAtLogon = $false
            }
            
            New-ADUser @userParams -ErrorAction Stop
        }
        else {
            Write-Host "User already exists: $samAccountName" -ForegroundColor Gray
        }
    }
}

Write-Host "Process completed." -ForegroundColor Green
