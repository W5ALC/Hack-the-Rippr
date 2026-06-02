# hac-da-rippr (Hack the Ripper)

An automated DVD ripper daemon with multi-feature disc support, comprehensive logging, and systemd integration.

## Features

- ✅ **Automatic DVD Detection** — Polls for inserted DVDs
- ✅ **Multi-Feature Support** — Rips all titles above minimum duration
- ✅ **PAL/NTSC Detection** — Automatic video standard detection
- ✅ **Duplicate Prevention** — Tracks ripped DVDs to avoid re-encoding
- ✅ **Desktop Notifications** — Notifies user of rip status
- ✅ **Comprehensive Logging** — All operations logged with rotation
- ✅ **Error Handling** — Robust retry logic and validation
- ✅ **Configuration** — Customizable via `/etc/auto_handbrake.conf`

## Dependencies

- `HandBrakeCLI` — DVD encoding
- `genisoimage` — DVD metadata reading
- `eject` — Drive control
- `libdvdcss` — CSS decryption (optional)
- `notify-send` — Desktop notifications (optional)

## Installation

See the [installer suite](./installer) documentation.

## Configuration

Edit `/etc/auto_handbrake.conf`:

```bash
DVD_DEVICE="/dev/sr0"
TARGETPATH="/home/user/Videos"
MINDURATION="3600"  # Minimum title duration in seconds
VIDEO_QUALITY="18"  # CRF quality (18 = visually lossless)
VIDEO_ENCODER="x264"
ENCODER_PRESET="slow"
```

## Running

```bash
sudo systemctl start hac-da-rippr
sudo systemctl enable hac-da-rippr  # Enable on boot
```

## Logs

- Installation log: `/var/log/hac-da-rippr-install.log`
- Runtime log: `/home/nowhereman/.log/auto_handbrake/auto_handbrake.log`
- Ripped DVDs index: `/home/nowhereman/.log/auto_handbrake/ripped_dvds.log`

## License

MIT
