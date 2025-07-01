# DNS Setup & Test Tool

A professional Bash script for configuring, testing, and restoring DNS settings on Linux systems. This tool automates DNS management, checks connectivity, and handles Windows-style line ending issues.

## Features
- **DNS Configuration**: Set up primary, secondary, and fallback DNS servers using `systemd-resolved`.
- **DNS Testing**: Test connectivity to DNS servers and display `/etc/resolv.conf` status.
- **Backup and Restore**: Create and restore DNS configuration backups.
- **Logging**: Log all actions and errors to `/var/log/dns-tool.log` or `/tmp/dns-tool.log`.
- **Line Ending Fix**: Automatically fix Windows-style (CRLF) line endings.
- **Interactive Menu**: User-friendly interface with color-coded output.
- **Dependency Management**: Automatically install required and optional dependencies.

## Requirements
- Linux system with `systemd` support.
- Root privileges (`sudo`).
- Internet connection for dependency installation (optional for operation).
- Required tools: `bash`, `ping`, `sed`, `systemctl`, `grep`, `cp`, `rm`, `touch`.
- Optional tool: `dos2unix`.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/dns-tool.git
   cd dns-tool
   ```
2. Make the script executable:
   ```bash
   chmod +x dns-tool.sh
   ```
3. Run the script as root:
   ```bash
   sudo ./dns-tool.sh
   ```

## Usage
Run the script with root privileges:
```bash
sudo ./dns-tool.sh
```

### Menu Options
1. **Setup and optimize system DNS**: Configure DNS servers (default: 1.1.1.1, 8.8.8.8, 9.9.9.9) or use custom servers.
2. **Test DNS and network status**: Check connectivity to DNS servers and display `/etc/resolv.conf`.
3. **Both (Setup + Test)**: Perform both configuration and testing.
4. **Restore DNS from backup**: Revert to the previous DNS configuration from `/etc/resolv.conf.backup`.
5. **Exit**: Exit the tool.

### Example
To set up DNS and test connectivity:
1. Select option `3` from the menu.
2. Enter custom DNS servers or press Enter to use defaults.
3. View test results for DNS connectivity.

## Configuration
- **Log File**: `/var/log/dns-tool.log` (falls back to `/tmp/dns-tool.log` if permissions are insufficient).
- **Configuration File**: `/etc/dns-tool.conf` (not used in the current version but reserved for future enhancements).
- **Default DNS Servers**:
  - Primary: `1.1.1.1` (Cloudflare)
  - Secondary: `8.8.8.8` (Google)
  - Fallback: `9.9.9.9` (Quad9)

## Logging
All actions, warnings, and errors are logged with timestamps to the specified log file for troubleshooting.

## Notes
- Ensure you have `systemd-resolved` installed for DNS configuration.
- The script requires root privileges to modify system files and services.
- If the script was transferred from a Windows system, it automatically fixes CRLF line endings.
- For issues or feature requests, please open an issue on GitHub.

## Contributing
Contributions are welcome! Please fork the repository, make changes, and submit a pull request.

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m "Add your feature"`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a pull request.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact
For updates and support, join our Telegram channel: [@YourChannelName](https://t.me/YourChannelName)