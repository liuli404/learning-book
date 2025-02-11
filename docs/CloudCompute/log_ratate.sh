#!/bin/bash

AUTHORIZED_USER="root"
ROTATE_FILE="/etc/logrotate.d/sudo"

#脚本必须使用root用户执行
if [ "$(whoami)" != "$AUTHORIZED_USER" ]; then
  echo "{\"msg\":\"Please run this script with the user '$AUTHORIZED_USER'!\"}"
  exit 1
fi

function config_sudo_log_rotate() {
  if [ -f "$ROTATE_FILE" ]; then
    rm -f "$ROTATE_FILE"
  fi
  touch "$ROTATE_FILE"
  chmod 640 "$ROTATE_FILE"

  cat >"$ROTATE_FILE" <<EOF
/var/log/sudo.log
{
    maxage 60
    rotate 30
    notifempty
    compress
    copytruncate
    missingok
    size +10M
    sharedscripts
    postrotate
        /bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true
    endscript
}
EOF

  echo "config success"
  return 0
}

function force_rotate() {
  logrotate -f /etc/logrotate.d/sudo
  if [ $? -ne 0 ]; then
    echo "force rotate failed."
    return 1
  fi
  echo "force rotate success"
  return 0
}

function delete_sudo_log() {
  rm -f /var/log/sudo.log
  echo "delete sudo log success."
  return 0
}

function rollback_sudo_log_rotate() {
  rm -f "$ROTATE_FILE"
  echo "rollback rotate config success"
}

function main() {
  #只能在FSM节点执行
  if [[ ! -f /opt/dsware/DSwareManagerNodeVersion ]]; then
    echo "ERROR, this operation can be performed only on the FSM node.]"
    return 1
  fi

  if [ $# -ne 1 ]; then
    echo "ERROR, parameter count not equal 1"
    return 1
  fi

  case $1 in
  config)
    config_sudo_log_rotate || return 1
    ;;

  force_rotate)
    force_rotate || return 1
    ;;

  rollback)
    rollback_sudo_log_rotate || return 1
    ;;

  delete_sudo_log)
  delete_sudo_log || return 1
  ;;
  *)
    echo "invalid parameter:${1}, support config/force_rotate/rollback"
    return 1
    ;;
  esac
}

main "$@"
exit $?
