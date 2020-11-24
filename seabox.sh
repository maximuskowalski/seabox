#!/usr/bin/env bash
set -euo pipefail

# Variables
USER=seed  # username
GROUP=seed # group
#
SET_DIR=/opt/seabox/sets     # set files location
SA_FILE=/opt/sa/mount/1.json # service account file for auth
SA_PATH=/opt/sa/mount        # service account files location
TAG="nc"                     # ro or nc to tag the remote as read only or no create
VFSMAX=100G                  # vfs-cache-max-size limit
CPORT=1                      # not used

# cloudbox defaults
MOUNTNAME=google      # we will be replacing this mount with the union of share drives
MOUNT_DIR=/mnt/remote # mount point of remote
MRG_DIR=/mnt/unionfs  # not used
MPORT=5572            # rc port
#

# FUNCTIONS

# check dirs and clean up in case of failure
check_firstrun() {
  ([ ! -f temp.conf ] || rm temp.conf)
  ([ -d "${MOUNT_DIR}" ] || mkmounce)
}

# mountpoints
mkmounce() {
  sudo mkdir ${MOUNT_DIR} && sudo chown ${USER}:${GROUP} ${MOUNT_DIR} && sudo chmod -R 775 ${MOUNT_DIR}
}

# rclone config
make_arrclone_conf() {
  sed '/^\s*#.*$/d' ${SET_DIR}/"$1" |
    while read -r name driveid; do
      rclone config create "${name}" drive scope drive server_side_across_configs true team_drive "${driveid}" service_account_file "${SA_FILE}" service_account_file_path "${SA_PATH}" >>"/home/${USER}/.config/rclone/rclone.conf"
    done
}

make_temp_conf() {
  sed '/^\s*#.*$/d' ${SET_DIR}/"$1" |
    while read -r name other; do
      echo -n "${name}::${TAG} " >>temp.conf
    done
}

mkreunion() {
  rclone config create "${MOUNTNAME}" union upstreams "${REUNION}"
}

# service file editor
sysdmaker() {
  sudo bash -c 'cat > /etc/systemd/system/rclone_vfs.service' <<EOF
# /etc/systemd/system/rclone_vfs.service
#########################################################################
# Title:         Cloudbox: Rclone VFS Mount                             #
# Author(s):     EnorMOZ                                                #
# URL:           https://github.com/cloudbox/cloudbox                   #
# --                                                                    #
#         Part of the Cloudbox project: https://cloudbox.works          #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

[Unit]
Description=Rclone VFS Mount
After=network-online.target

[Service]
User=${USER}
Group=${GROUP}
Type=notify
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/rclone mount \\
          --config=/home/${USER}/.config/rclone/rclone.conf \\
          --allow-other \\
          --allow-non-empty \\
          --rc \\
          --rc-addr=localhost:${MPORT} \\
          --vfs-read-ahead=128M \\
          --vfs-read-chunk-size=64M \\
          --vfs-read-chunk-size-limit=2G \\
          --vfs-cache-mode=full \\
          --vfs-cache-max-age=24h \\
          --vfs-cache-max-size=${VFSMAX} \\
          --fast-list \\
          --buffer-size=64M \\
          --dir-cache-time=1h \\
          --timeout=10m \\
          --umask=002 \\
          --syslog \\
          -v \\
          ${MOUNTNAME}: ${MOUNT_DIR}
ExecStop=/bin/fusermount -uz ${MOUNT_DIR}
Restart=on-abort
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=default.target
EOF
}

# stop existing services
stopper() {
  sudo systemctl stop rclone_vfs.service
  sudo systemctl stop rclone_vfs_primer.service
  sudo systemctl stop mergerfs.service
}

# start services
starter() {
  sudo systemctl start rclone_vfs.service
  nohup sh sudo systemctl start rclone_vfs_primer.service &>/dev/null &
  sudo systemctl start mergerfs.service
}

# setlist
stopper
check_firstrun
echo "stopping mount"
make_arrclone_conf "$1"
make_temp_conf "$1"
REUNION=$(cat temp.conf)
mkreunion
sysdmaker
sudo systemctl daemon-reload
starter
rm temp.conf
echo "mounts completed"
# eof
