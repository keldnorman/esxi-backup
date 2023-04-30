#!/bin/bash
#set -x
clear
#--------------------------------------------------------
# About
#--------------------------------------------------------
# ESXi Backup script - (C)opyleft Keld Norman, April 2023
# 
# This script can take a backup of any ESXi host to 
# to local storage (eg a NAS or alike)
#
#--------------------------------------------------------
# Banner for the 1337'ishness
#--------------------------------------------------------
cat << "EOF"
 
 ____ <==> ____
 \___\(**)/___/  ESXi Backup Script
  \___|  |___/    
      L  J     (C)opyleft Keld Norman
      |__|           April 2023
       vv             

EOF
#--------------------------------------------------------
# Variables
#--------------------------------------------------------
SAVE_DAYS=30
ESXI_HOSTS="10.0.0.2 10.0.0.3 10.0.0.4 10.0.0.5 10.0.0.6"
DATE=$(date +%Y-%m-%d)
REMOTE_DIR="/scratch/downloads"
BACKUP_DIR="/volume1/backup/esxi"
#--------------------------------------------------------
# Variables for Secure Shell
#--------------------------------------------------------
SSH_KEY_FILE="${HOME}/.ssh/id_rsa"
SSH_KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"
SSH_REMOTE_AUTHORIZED_DIR="/etc/ssh/keys-root"
SSH_REMOTE_AUTHORIZED_FILE="${SSH_REMOTE_AUTHORIZED_DIR}/authorized_keys"
#--------------------------------------------------------
# Utilities:
#--------------------------------------------------------
DIRNAME="/bin/dirname"
SCP="/bin/scp"
SSH="/bin/ssh"
SSH_KEY_GEN="/bin/ssh-keygen"
SSH_KEYSCAN="/usr/local/bin/ssh-keyscan"
#--------------------------------------------------------
# Pre checks
#--------------------------------------------------------
# Check if the utilities this script needs exist
for UTIL in ${SSH_KEY_GEN} ${SSH} ${SSH_KEYSCAN} ${SCP} ${DIRNAME}; do
 if [ ! -x ${UTIL} ]; then 
  printf "\n ### ERROR - Cant find ${UTIL}\n\n"
  exit 1
 fi
done
# Check if the backup directory exist
if [ ! -d ${BACKUP_DIR} ]; then 
 mkdir -p -m 700 ${BACKUP_DIR}
fi
chown root:root ${BACKUP_DIR}
chmod 700 ${BACKUP_DIR}
#--------------------------------------------------------
# Check if the SSH key file exist and if not make one
#--------------------------------------------------------
if [ ! -s "${SSH_KEY_FILE}" ]; then
 printf " %-50s" "Generating SSH key ${SSH_KEY_FILE}"
 ${SSH_KEY_GEN} -t rsa -N "" -f "${SSH_KEY_FILE}"
 if [ $? -ne 0 ]; then
  echo "[FAILED]"
  printf "\n ### ERROR: SSH key generation failed ( ${SSH_KEY_GEN} -t rsa -N \"\" -f \"${SSH_KEY_FILE}\"\n\n"
  exit 1
 fi
 echo "[OK]"
fi
#--------------------------------------------------------
# Take backup of all ESXI HOSTS
#--------------------------------------------------------
for ESXI_HOST in ${ESXI_HOSTS}; do
 #--------------------------------------------------------
 # Check if this remote system runs a ssh server
 #--------------------------------------------------------
 # Check if netcat (nc) or telnet utilities exist
 printf " %-50s" "Checking for a SSH server on ${ESXI_HOST}"
 if command -v nc >/dev/null 2>&1 ; then # Use netcat to check SSH port
  timeout 5s nc -z -w5 ${ESXI_HOST} 22 >/dev/null 2>&1
  if [ $? -eq 0 ]; then
   echo "[OK]"
  else
   echo "[FAILED]"
   printf "\n ERROR: Could not connect to SSH server on ${ESXI_HOST}!\n\n"
   exit 1
  fi
 elif command -v telnet >/dev/null 2>&1 ; then
  timeout 5s bash -c "echo quit | telnet ${ESXI_HOST} 22" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
   echo "[OK]"
  else
   echo "[FAILED]"
   printf "\n ERROR: Could not connect to SSH server on ${ESXI_HOST}!\n\n"
   exit 1
  fi
 else
   echo "[SKIPPED]" # Neither nc nor telnet are installed.
 fi
 #--------------------------------------------------------
 # Check if a ssh known_hosts file exist 
 #--------------------------------------------------------
 if [ ! -f "${SSH_KNOWN_HOSTS_FILE}" ]; then
  printf " %-50s" "Creating an empty ${SSH_KNOWN_HOSTS_FILE}"
  touch "${SSH_KNOWN_HOSTS_FILE}"
  chmod 600 "${SSH_KNOWN_HOSTS_FILE}"
  echo "[OK]"
 fi
 #--------------------------------------------------------
 # Check if the remote hosts key is known or has changed
 #--------------------------------------------------------
 if ${SSH_KEY_GEN} -H -F "${ESXI_HOST}" -f "${SSH_KNOWN_HOSTS_FILE}" | grep -q "not found in"; then
  printf " %-50s" "Adding remote host known_hosts"
  ${SSH_KEYSCAN} -t rsa "${ESXI_HOST}" >> "${SSH_KNOWN_HOSTS_FILE}"
  if [ $? -eq 0 ]; then
   echo "[OK]"
  else
   echo "[FAILED]"
   printf "\n ERROR: ${SSH_KEYSCAN} -t rsa \"$ESXI_HOST\" >> \"$KNOWN_HOSTS_FILE\" failed!\n\n"
   exit 1
  fi
 elif ${SSH_KEY_GEN} -H -F "${ESXI_HOST}" -f "${SSH_KNOWN_HOSTS_FILE}" | grep -q "mismatch"; then
  # Host key has changed. Updating it in the known_hosts file
  printf " %-50s" "Updating known_hosts"
  ${SSH_KEY_GEN} -R "${ESXI_HOST}" -f "${SSH_KNOWN_HOSTS_FILE}"
  ${SSH_KEYSCAN} -t rsa "${ESXI_HOST}" >> "${SSH_KNOWN_HOSTS_FILE}"
  if [ $? -eq 0 ]; then
   echo "[OK]"
  else
   echo "[FAILED]"
   printf "\n ERROR: ${SSH_KEYSCAN} -t rsa \"${ESXI_HOST}\" >> \"${SSH_KNOWN_HOSTS_FILE}\" failed!\n\n"
   exit 1
  fi
 fi
 #--------------------------------------------------------
 # Check if SSH connection to ESXi works with a ssh key
 #--------------------------------------------------------
 printf " %-50s" "Connecting to ESXi system"
 if ! ${SSH} -o ConnectTimeout=5 -o BatchMode=yes -q -i ${SSH_KEY_FILE} root@${ESXI_HOST} "echo 'connected'" >/dev/null 2>&1 ; then 
  echo "[PROMPTED]"
  printf "\n Please enter the password for root@${ESXI_HOST} when prompted:\n\n  "
  CHECK="if [ ! -d ${SSH_REMOTE_AUTHORIZED_DIR} ]; then 
   mkdir -p ${SSH_REMOTE_AUTHORIZED_DIR} > /dev/null 2>&1
  fi
  chmod 755 ${SSH_REMOTE_AUTHORIZED_DIR} > /dev/null 2>&1
  chown root:root ${SSH_REMOTE_AUTHORIZED_DIR} > /dev/null 2>&1
  if [ ! -e ${SSH_REMOTE_AUTHORIZED_FILE} ]; then 
   touch ${SSH_REMOTE_AUTHORIZED_FILE} > /dev/null 2>&1
  fi
  chmod 640 ${SSH_REMOTE_AUTHORIZED_FILE} > /dev/null 2>&1 && \
  chown root:root ${SSH_REMOTE_AUTHORIZED_FILE} > /dev/null 2>&1
  if [ \$(grep -c '$(cat ${SSH_KEY_FILE}.pub)' ${SSH_REMOTE_AUTHORIZED_FILE}) -eq 0 ]; then
   echo '$(cat ${SSH_KEY_FILE}.pub)' >> ${SSH_REMOTE_AUTHORIZED_FILE}
  fi"
  ${SSH} -o ConnectTimeout=5 -i ${SSH_KEY_FILE} root@$ESXI_HOST "${CHECK}"
  printf " %-50s" "Connecting to ESXi system"
  if ! ${SSH} -o ConnectTimeout=5 -o BatchMode=yes -q -i ${SSH_KEY_FILE} root@${ESXI_HOST} "echo 'connected'" >/dev/null 2>&1 ; then 
   echo "[FAILED]"
   printf "\n ### ERROR: Adding the SSH key to root@${ESXI_HOST}!\n\n"
   exit 1
  else
   echo "[OK]"
  fi
 else 
  echo "[OK]"
 fi
 #--------------------------------------------------------
 # Check if the remote host is an ESXi host
 #--------------------------------------------------------
 if ! ${SSH} -o ConnectTimeout=5 root@${ESXI_HOST} 'vmware -v' 2>/dev/null | grep -q "ESXi"; then
  printf "\n ### ERROR: The remote machine at ${ESXI_HOST} is not running ESXi!"
  exit 1 
 fi
 #--------------------------------------------------------
 # Check if the remote host has the vim-cmd command
 #--------------------------------------------------------
 if ! ${SSH} -o ConnectTimeout=5 root@${ESXI_HOST} 'vim-cmd -v' 2>/dev/null | grep -q "Host Agent"; then
  printf "\n ### ERROR: The remote machine at ${ESXI_HOST} does not have the vim-cmd utility!"
  exit 1 
 fi
 #--------------------------------------------------------
 # Collect data about the remote ESXi host
 #--------------------------------------------------------
 ESX_VERSION=$(${SSH} -o ConnectTimeout=5 root@${ESXI_HOST} 'vmware -v' 2>/dev/null)
 if [ -z "${ESX_VERSION}" ]; then 
  ESX_VERSION="Unknown"
 fi
 ESX_HOSTNAME=$(${SSH} -o ConnectTimeout=5 root@${ESXI_HOST} 'hostname' 2>/dev/null)
 if [ -z "${ESX_HOSTNAME}" ]; then 
  ESX_HOSTNAME="${ESXI_HOST}"
 fi
 if [ ! -d ${BACKUP_DIR}/${ESX_HOSTNAME} ]; then 
  mkdir -p -m 700 ${BACKUP_DIR}/${ESX_HOSTNAME} 
 fi
 LOCAL_BACKUP_DIR="${BACKUP_DIR}/${ESX_HOSTNAME}"
 #--------------------------------------------------------
 # Delete local backups older than 30 days
 #--------------------------------------------------------
 # Ensure at least one file is left and it's greater than 0 bytes
 OLD_BACKUPS=$(find ${LOCAL_BACKUP_DIR} -name "backup-*" -type f -mtime +30 2>/dev/null | wc -l)
 if [ $OLD_BACKUPS -gt 1 ]; then
  printf " %-50s" "Cleaning up old backups > ${SAVE_DAYS} old.."
  find ${BACKUP_DIR} -name "*-configBundle-${ESX_HOSTNAME}.tgz" -type f -mtime +30 -exec rm {} \;
  if [ $? -ne 0 ]; then
   echo "[FAILED]"
   printf "\n ### ERROR: Deletion of old backup files failed!\n\n"
   exit 1
  fi
  echo "[OK]"
 fi
 #--------------------------------------------------------
 # Sync backup of ESXi settings
 #--------------------------------------------------------
 printf " %-50s" "Requesting a sync on remote ESXi host"
 ${SSH} root@${ESXI_HOST} "vim-cmd hostsvc/firmware/sync_config" 
 if [ $? -ne 0 ]; then
  echo "[FAILED]"
  echo "Error: Unable to run: vim-cmd hostsvc/firmware/sync_config"
  exit 1
 else
  echo "[OK]"
 fi
 #--------------------------------------------------------
 # Take backup of ESXi settings
 #--------------------------------------------------------
 printf " %-50s" "Backing up ${ESIX_HOST}"
 if [ $(${SSH} root@${ESXI_HOST} "vim-cmd hostsvc/firmware/backup_config" 2>/dev/null|grep -c "Bundle can be downloaded at") -eq 0 ]; then 
  echo "[FAILED]"
  printf "\n ### Error: ${SSH} root@${ESXI_HOST} \"vim-cmd hostsvc/firmware/backup_config\" failed!\n\n"
  exit 1
 else
  ${SCP} -q -4 -C root@${ESXI_HOST}:/scratch/downloads/*/configBundle-${ESX_HOSTNAME}.tgz ${LOCAL_BACKUP_DIR}/${DATE}-configBundle-${ESX_HOSTNAME}.tgz
  if [ -s ${LOCAL_BACKUP_DIR}/${DATE}-configBundle-${HOSTNAME}.tgz ]; then 
   echo "[FAILED]"
   printf "\n ### Error: ${SCP} root@${ESXI_HOST}:/scratch/downloads/*/configBundle-${ESX_HOSTNAME}.tgz ${LOCAL_BACKUP_DIR}/${DATE}-configBundle-${ESX_HOSTNAME}.tgz failed\n\n"
   exit 1
  else
   echo "[OK]"
  fi
 fi
 printf "\n $(date) - ESXi backup of ${ESXI_HOST} ${ESX_HOSTNAME} completed successfully\n\n"
done
#--------------------------------------------------------
# HOW TO RESTORE:
#--------------------------------------------------------
# Set the esxi to maint mode: 
# esxcli system maintenanceMode set –enable yes
# or
# vim-cmd hostsvc/maintenance_mode_enter
#---------------------
# scp (configBundle-xxxx.tgz) to esxi:/tmp/
# or
#  mv /tmp/configBundle-esxi6-7b.localdomain.tgz /tmp/configBundle.tgz
#----------------------------
# run the restore settings command:
# vim-cmd hostsvc/firmware/restore_config /tmp/configBundle.tgz
#-----------------------------
# Exit the maintenance mode:
# esxcli system maintenanceMode set –enable no
# or
# vim-cmd hostsvc/maintenance_mode_exit
#-------------------------------
