# Scripts Repository

This repository contains a collection of PowerShell scripts for Active Directory management and system health checks.

## Scripts Overview

### 1. [AD User Creation](create-users.ps1)
Automates the creation of test users in Active Directory with a nested OU structure.
- **Key Features**: Creates a parent 'Company' OU, sub-OUs (Sales, IT), generates multiple users with common attributes, and fake phone numbers.
- **Usage**: `.\create-users.ps1 -OUNames 'Sales','IT' -UsersPerOU 5`

### 2. [Specops Health Check](spp_health_check.ps1)
Verifies network connectivity for Specops Password Policy (SPP) and Breached Password Protection (BPP).
- **Key Features**: Tests external endpoints, performs Deep CRL validation via `certutil`, and checks internal port connectivity to PDC and Arbiters.
- **Usage**: `.\spp_health_check.ps1`

### 3. [SMTP Server Setup](smtp/)
Tools and documentation for setting up a fake SMTP server (`smtp4dev`) for testing.
- **Key Features**: winget-based installation, helper setup script.
- **Usage**: See [smtp/README.md](smtp/README.md)

## Prerequisites
- Windows PowerShell 5.1 or PowerShell 7
- Active Directory PowerShell module (RSAT)
- Appropriate administrative permissions in the target domain

## Getting Started
1. Clone the repository: `git clone https://github.com/n-trang/scripts.git`
2. Navigate to the script directory.
3. Run the desired script with administrative privileges.
