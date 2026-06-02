# hac-da-rippr Installer Suite

Professional installation and management utilities for hac-da-rippr.

## Quick Start

### Interactive Installation

```bash
sudo ./installer/menu.sh
```

This presents a menu-driven interface for all operations:

1. **Install** — Fresh installation
2. **Upgrade** — Update existing installation
3. **Reconfigure** — Change settings
4. **Health Check** — Verify system health
5. **Uninstall** — Remove installation
6. **View Logs** — Display installation logs

### Command-Line Installation

```bash
sudo ./installer/install.sh
```

## Installation Scripts

### `lib.sh`

Common functions used by all installer scripts:
- Distribution detection
- Optical drive detection
- Configuration management
- Health checks
- Logging

### `install.sh`

Performs a fresh installation:
1. Detects Linux distribution
2. Checks internet connectivity
3. Detects optical drives
4. Installs dependencies
5. Installs hac-da-rippr executable
6. Installs systemd service
7. Generates configuration
8. Verifies installation
9. Starts service

### `upgrade.sh`

Upgrades an existing installation:
1. Verifies existing installation
2. Backs up current configuration
3. Stops service
4. Replaces executable and service file
5. Restarts service
6. Verifies upgrade

### `reconfigure.sh`

Modifies configuration:
1. Re-detects optical drives
2. Prompts for new settings (with whiptail)
3. Validates target directory
4. Backs up current config
5. Writes new configuration
6. Restarts service

### `uninstall.sh`

Removes installation:
1. Verifies installation exists
2. Prompts for preservation options:
   - Keep configuration?
   - Keep ripped videos?
   - Keep logs?
3. Stops and disables service
4. Removes files
5. Cleans up based on user preferences

### `healthcheck.sh`

Verifies system health:
- HandBrakeCLI availability
- Executable presence
- Service file presence
- Configuration validity
- Service status (enabled/running)
- Optical drive detection
- Target directory writability
- Disk space availability

### `menu.sh`

Interactive menu system (uses whiptail if available):
- Main menu loop
- Calls other scripts as needed
- Log viewer

## Configuration

After installation, edit `/etc/auto_handbrake.conf`:

```bash
# Monitor this optical drive
DVD_DEVICE="/dev/sr0"

# Save ripped videos here
TARGETPATH="/home/user/Videos"

# Skip titles shorter than this
MINDURATION="3600"  # 1 hour

# Video quality (18=lossless, 23=default, 28=low)
VIDEO_QUALITY="18"

# Video encoder (x264 or x265)
VIDEO_ENCODER="x264"

# Encoding speed preset (slow=better quality, faster=quicker)
ENCODER_PRESET="slow"

# Audio handling
AUDIO_ENCODER="copy:ac3,aac"
DEFAULT_AUDIO="eng"

# Polling settings
POLL_INTERVAL=30
MAX_RETRIES=3
```

## Service Management

### Start/Stop Service

```bash
sudo systemctl start hac-da-rippr
sudo systemctl stop hac-da-rippr
```

### Enable/Disable on Boot

```bash
sudo systemctl enable hac-da-rippr
sudo systemctl disable hac-da-rippr
```

### View Status

```bash
sudo systemctl status hac-da-rippr
```

### View Logs

```bash
# Recent logs
sudo journalctl -u hac-da-rippr -n 50

# Follow logs
sudo journalctl -u hac-da-rippr -f

# Installation logs
sudo tail -f /var/log/hac-da-rippr-install.log
```

## Supported Distributions

- Ubuntu 18.04+
- Debian 10+
- Linux Mint 19+
- Pop!_OS 20.04+

## Prerequisites

- Root access
- Internet connection (for dependency installation)
- Optical drive (optional, for DVD ripping)
- ~1GB free disk space (for dependencies)
- Storage space for ripped videos (typically 4-8GB per DVD)

## Troubleshooting

### Service won't start

```bash
# Check logs
sudo journalctl -u hac-da-rippr -n 100

# Verify configuration
sudo bash -n /etc/auto_handbrake.conf

# Check HandBrakeCLI
HandBrakeCLI --version
```

### Optical drive not detected

```bash
# Check for drive devices
ls -la /dev/sr* /dev/cd*

# Check permissions
ls -la /dev/sr0

# Verify current configuration
grep DVD_DEVICE /etc/auto_handbrake.conf

# Update with correct device
sudo ./installer/reconfigure.sh
```

### Permission issues

```bash
# Check current user
whoami

# Verify target directory permissions
ls -la /home/nowhereman/Videos

# Change ownership if needed
sudo chown $USER:$USER /home/nowhereman/Videos
```

## Security Considerations

- The service runs as root (required for DVD device access)
- Configuration file contains no sensitive data
- All operations are logged to `/var/log/hac-da-rippr-install.log`
- Service uses systemd sandboxing features

## License

MIT
