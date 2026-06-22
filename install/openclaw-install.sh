#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vishnusenthil-16
# License: MIT | https://github.com/vishnusenthil-16/ProxmoxVED/raw/main/LICENSE
# Source: https://openclaw.ai

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

# openclaw runs its gateway as a systemd --user service, so unlike most scripts
# (which run as root) it needs a real user with linger enabled. This is a
# deliberate deviation from Anti-Pattern #9, not an oversight.
msg_info "Creating openclaw User"
useradd -m -s /bin/bash openclaw
loginctl enable-linger openclaw
msg_ok "Created openclaw User"

# Lets systemctl --user work on future interactive logins. The install steps
# below export the same vars inline because runuser does not source .bashrc.
msg_info "Configuring User Environment"
cat <<'EOF' >>/home/openclaw/.bashrc

if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
fi
EOF
msg_ok "Configured User Environment"

OPENCLAW_UID=$(id -u openclaw)

# openclaw is an npm app with a bespoke installer (not a GitHub release), so we
# use its official installer instead of fetch_and_deploy_gh_release. Node 22 is
# already on PATH from setup_nodejs, so the installer reuses it. Onboarding and
# prompts are off for a fully unattended install.
msg_info "Installing openclaw"
$STD runuser -u openclaw -- env \
  XDG_RUNTIME_DIR="/run/user/${OPENCLAW_UID}" \
  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${OPENCLAW_UID}/bus" \
  OPENCLAW_NO_ONBOARD=1 \
  bash -lc 'curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt'
msg_ok "Installed openclaw"

# openclaw manages its own systemd --user unit via 'gateway install', so we do
# NOT write a /etc/systemd/system unit and do NOT daemon-reload (Anti-Pattern #13).
msg_info "Setting up Gateway Service"
$STD runuser -u openclaw -- env \
  XDG_RUNTIME_DIR="/run/user/${OPENCLAW_UID}" \
  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${OPENCLAW_UID}/bus" \
  bash -lc 'openclaw gateway install && openclaw gateway restart'
msg_ok "Set up Gateway Service"

motd_ssh
customize
cleanup_lxc
