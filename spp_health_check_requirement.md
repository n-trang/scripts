# Specops Password Policy (SPP) Health Check Requirements

This document outlines the network connectivity requirements for Specops Password Policy (SPP) and Breached Password Protection (BPP).

## Connectivity Requirements for SPP Admin Tools and BPP Express

The following URLs must be reachable from the machine where SPP Admin tools and BPP Express are installed.

| URL | Description | Protocol | Port |
| :--- | :--- | :--- | :--- |
| `https://breach-protection.specopssoft.com` | Web endpoint | TCP | 443 |
| `https://download.specopssoft.com` | Web endpoint | TCP | 443 |

### CRL Verification for Admin Tools and BPP Express

Certificate Revocation List (CRL) checks are required for the above endpoints. Since these use wildcard patterns, we test representative hosts:

| URL | Description | Protocol | Port | Representative Host for Testing |
| :--- | :--- | :--- | :--- | :--- |
| `https://*.c.lencr.org` | Certificate CRL endpoint | TCP | 443 | `r3.c.lencr.org`, `r11.c.lencr.org` |
| `http://*.c.lencr.org` | Certificate CRL endpoint | TCP | 80 | `r3.c.lencr.org`, `r11.c.lencr.org` |
| `https://crl.godaddy.com/` | Certificate CRL endpoint | TCP | 443 | `crl.godaddy.com` |
| `http://crl.godaddy.com/` | Certificate CRL endpoint | TCP | 80 | `crl.godaddy.com` |

## Connectivity Requirements for BPP Complete (Arbiter Servers)

All Arbiter servers require access to the following:

| URL | Description | Protocol | Port |
| :--- | :--- | :--- | :--- |
| `https://breach-protection.specopssoft.com` | Web endpoint | TCP | 443 |

### CRL Verification for BPP Complete

Testing representative hosts for wildcard patterns:

| URL | Description | Protocol | Port | Representative Host for Testing |
| :--- | :--- | :--- | :--- | :--- |
| `https://*.c.lencr.org` | Certificate CRL endpoint | TCP | 443 | `r3.c.lencr.org`, `r11.c.lencr.org` |
| `http://*.c.lencr.org` | Certificate CRL endpoint | TCP | 80 | `r3.c.lencr.org`, `r11.c.lencr.org` |

## Internal Connectivity Requirements

In addition to external URLs, the following internal ports must be open between infrastructure components:

| Source | Destination | Protocol | Port | Description |
| :--- | :--- | :--- | :--- | :--- |
| All Domain Controllers | Arbiter Server(s) | TCP | 4383 | Communication to Arbiter |
| PP Admin Tool | Arbiter Server(s) | TCP | 4383 | Admin tool to Arbiter |
| PP Admin Tool | PDC Emulator | TCP | 4385 | Admin tool to PDC |

## IP Address Range Information

> [!IMPORTANT]
> It is strongly recommended to use URL or hostname-based allowlists, as IP addresses may change over time.

If IP-based rules are mandatory, Arbiter servers must have access to the following IP range:

- `138.91.126.220/30`

*Note: More granular filtering is not supported as exact IP addresses within this range are subject to change.*
