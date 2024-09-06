# Linux Mint Primer

Streamline and optimize your Linux Mint 22 or 21.3

```bash
sudo apt install -y git
git clone https://github.com/MK2112/Linux-Mint-Primer
cd Linux-Mint-Primer
chmod +x mint-primer.sh
sudo ./mint-primer.sh
```
This project is a fork of [aaron-dev-git/Linux-Mint-Debloater](https://github.com/aaron-dev-git/Linux-Mint-Debloater).

## Features

- **Backup:** Create a system snapshot before making changes
- **Debloat:** Remove pre-installed, unnecessary programs
- **Optimize:** Enhance system performance, configure specifically for portable use, decrease boot time, turn off Flatpak
- **Secure:** Install security updates, reduce telemetry
- **Harden:** Setup and configure UFW firewall, SSH Hardening
- **Customize:** Install a list of programs
- **Automate:** Set the value of `auto` in `config.txt` to `true` to skip all user interactions and instead configure based on `config.txt` settings.

## Requirements

- Linux Mint (tested on 21.3, 22 Stable)
- Root privileges
