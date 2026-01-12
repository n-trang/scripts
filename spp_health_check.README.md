# spp_health_check.ps1

Verifies network connectivity and certificate revocation list (CRL) accessibility for Specops Password Policy (SPP) and Breached Password Protection (BPP).

## Features
- **External Endpoint Tests**: Checks connectivity to Specops and Let's Encrypt endpoints.
- **Deep CRL Validation**: Uses `certutil` to verify that the local OS can successfully fetch and process CRLs for required certificates.
- **Internal Port Checks**: 
  - **PDC Emulator**: Tests port 4385 for Admin Tool connectivity.
  - **Arbiters**: Tests port 4383 for DC-to-Arbiter communication.
- **Auto-Discovery**: Attempts to automatically find the PDC and Arbiter servers in the domain.

## Parameters
- `ArbiterServers`: Optional list of Arbiter server hostnames to test. If omitted, the script attempts auto-discovery.

## Usage
Run as Administrator:
```powershell
.\spp_health_check.ps1
```

## Requirements
See [spp_health_check_requirement.md](spp_health_check_requirement.md) for detailed network requirements and representative hosts.
