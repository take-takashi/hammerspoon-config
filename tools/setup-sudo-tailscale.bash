#!/bin/bash
USER=$(whoami)
FILE=/etc/sudoers.d/tailscaled

echo "$USER ALL=(ALL) NOPASSWD: /opt/homebrew/bin/tailscaled" | sudo tee "$FILE" > /dev/null
sudo chmod 0440 "$FILE"
sudo visudo -cf "$FILE"