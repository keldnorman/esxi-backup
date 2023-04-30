# HOW TO TAKE A BACKUP

Quick script to take backup of your ESXi configurations

Edit the script and add the IP adresses of the ESXi hosts you want to backup to the variable called: 
ESXI_HOSTS=""

Example: ESXI_HOSTS="10.0.0.2 10.0.0.3 10.0.0.4"

Then run the script: 

./backup_esxi.sh

# HOW TO RESTORE:

Set the esxi to maint mode: 

esxcli system maintenanceMode set –enable yes
 or
vim-cmd hostsvc/maintenance_mode_enter

Copy the backup to the esxi: 

scp (configBundle-xxxx.tgz) to esxi:/tmp/
or
mv /tmp/configBundle-esxi6-7b.localdomain.tgz /tmp/configBundle.tgz

Run the restore settings command:

vim-cmd hostsvc/firmware/restore_config /tmp/configBundle.tgz

Exit the maintenance mode:

esxcli system maintenanceMode set –enable no
or
vim-cmd hostsvc/maintenance_mode_exit

# EXAMPLE

root@nas:/volume1/backup/esxi# ./backup_esxi.sh
 
 ____ <==> ____
 \___\(**)/___/  ESXi backup script
  \___|  |___/    
      L  J     (C)opyleft Keld Norman
      |__|           April 2023
       vv             

 Checking for a SSH server on 10.0.0.2             [OK]
 Connecting to ESXi system                         [OK]
 Requesting a sync on remote ESXi host             [OK]
 Backing up                                        [OK]

 Sun Apr 30 02:06:54 CEST 2023 - ESXi backup of 10.0.0.2 esxintra.adm.lan completed successfully

 Checking for a SSH server on 10.0.0.3             [OK]
 Connecting to ESXi system                         [OK]
 Requesting a sync on remote ESXi host             [OK]
 Backing up                                        [OK]

 Sun Apr 30 02:07:03 CEST 2023 - ESXi backup of 10.0.0.3 esxdmz.adm.lan completed successfully

 Checking for a SSH server on 10.0.0.4             [OK]
 Connecting to ESXi system                         [OK]
 Requesting a sync on remote ESXi host             [OK]
 Backing up                                        [OK]

 Sun Apr 30 02:07:10 CEST 2023 - ESXi backup of 10.0.0.4 esxtor.adm.lan completed successfully

 Checking for a SSH server on 10.0.0.5             [OK]
 Connecting to ESXi system                         [OK]
 Requesting a sync on remote ESXi host             [OK]
 Backing up                                        [OK]

 Sun Apr 30 02:07:18 CEST 2023 - ESXi backup of 10.0.0.5 esxwin.adm.lan completed successfully

 Checking for a SSH server on 10.0.0.6             [OK]
 Connecting to ESXi system                         [PROMPTED]

 Please enter the password for root@10.0.0.6 when prompted:

Password: 
 Connecting to ESXi system                         [OK]
 Requesting a sync on remote ESXi host             [OK]
 Backing up                                        [OK]

 Sun Apr 30 02:07:33 CEST 2023 - ESXi backup of 10.0.0.6 esxdmz2.adm.lan completed successfully

root@nas:/volume1/backup/esxi# 
