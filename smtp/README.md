# SMTP Server Setup (smtp4dev)

This directory contains scripts and documentation for setting up `smtp4dev`, a fake SMTP server for testing.

## Installation
`smtp4dev` has been installed using `winget`.

If the command `smtp4dev` is not recognized, you may need to:
1. Restart your PowerShell terminal.
2. Alternatively, run the setup script to re-verify:
   ```powershell
   .\setup-smtp.ps1
   ```

## Usage
To start the server:
```powershell
smtp4dev
```

### Default Configuration
- **SMTP Port**: 25 (or 2525)
- **Web Interface**: [http://localhost:5000](http://localhost:5000)

## Verified Functionality
- [x] Installed via winget (`Rnwood.Smtp4dev`).
- [x] Helper script `setup-smtp.ps1` created.

> [!TIP]
> Use this server to test the users created by `create-users.ps1`. You can send test emails to `[username]@tn.com` and they will appear in the smtp4dev web interface.
