# esxi-backup
Quick script to take backup of your ESXi configurations

Edit the script and add the IP adresses of the ESXi hosts you want to backup to the variable called: 
ESXI_HOSTS=""

Example: ESXI_HOSTS="10.0.0.2 10.0.0.3 10.0.0.4"

Then run the script: 

./backup_esxi.sh

HOW TO RESTORE:

# Set the esxi to maint mode: 
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

