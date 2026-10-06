#!/bin/sh
# Install the HP Elite x2 G4 mute-LED follower. Run as root.
set -eu
cd "$(dirname "$0")"

install -m 755 hp-elite-x2-mute-leds /usr/local/sbin/hp-elite-x2-mute-leds
install -m 644 hp-elite-x2-mute-leds.service /etc/systemd/system/hp-elite-x2-mute-leds.service
install -d /etc/systemd/system-sleep
install -m 755 system-sleep/hp-elite-x2-mute-leds /etc/systemd/system-sleep/hp-elite-x2-mute-leds
install -m 644 90-hp-elite-x2-mute-leds.rules /etc/udev/rules.d/90-hp-elite-x2-mute-leds.rules

systemctl daemon-reload
systemctl enable --now hp-elite-x2-mute-leds.service
udevadm control --reload-rules

echo "installed"
