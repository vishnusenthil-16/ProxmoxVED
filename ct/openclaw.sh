#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/vishnusenthil-16/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vishnusenthil-16
# License: MIT | https://github.com/vishnusenthil-16/ProxmoxVED/raw/main/LICENSE
# Source: https://openclaw.ai

APP="OpenClaw"
var_tags="${var_tags:-ai;chatops}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # openclaw is a per-user install (no /opt dir), so check the user instead.
  if ! id -u openclaw &>/dev/null; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # openclaw is an npm app, not a GitHub release, so check_for_gh_release does
  # not apply. Re-running the installer updates the package and restarts the
  # loaded gateway itself. Config in ~/.openclaw is untouched, so no backup.
  OPENCLAW_UID=$(id -u openclaw)
  msg_info "Updating ${APP}"
  $STD runuser -u openclaw -- env \
    XDG_RUNTIME_DIR="/run/user/${OPENCLAW_UID}" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${OPENCLAW_UID}/bus" \
    OPENCLAW_NO_ONBOARD=1 \
    bash -lc 'curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt'
  msg_ok "Updated ${APP}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} The Control UI listens locally inside the container on:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://127.0.0.1:18789${CL}"
echo -e "${INFO}${YW} Reach it from your machine with an SSH tunnel:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}ssh -L 18789:127.0.0.1:18789 root@${IP}${CL}"
