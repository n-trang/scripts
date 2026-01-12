# create-users.ps1

A PowerShell script to automate the creation of test Organizational Units (OUs) and users in Active Directory.

## Features
- **Nested OU Structure**: Creates a parent OU (default: `Company`) and specified sub-OUs.
- **Automated User Generation**: Creates a configurable number of users per OU.
- **Common Attributes**:
  - SamAccountName (e.g., sales1)
  - DisplayName (e.g., Sales 1 (Test))
  - Email & UPN (e.g., sales1@tn.com)
  - Office Phone (Randomly generated 555-01XX)
- **Safe Execution**: Checks for existing OUs and users before creation.

## Parameters
- `ParentOU`: Name of the parent OU to create at the domain root (default: 'Company').
- `OUNames`: Array of sub-OU names (default: 'Sales', 'IT').
- `UsersPerOU`: Number of users to create in each sub-OU (default: 5).
- `DomainSuffix`: Domain for UPN and Email (default: 'tn.com').
- `DefaultPassword`: Initial password for all created users.

## Usage
Run as Administrator:
```powershell
.\create-users.ps1 -ParentOU 'TestLab' -OUNames 'Dev','Ops' -UsersPerOU 10
```
