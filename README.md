# esxi-backup
Quick script to take backup of your ESXi configurations

Edit the script and add the IP adresses of the ESXi hosts you want to backup to the variable called: 
ESXI_HOSTS=""

Example: ESXI_HOSTS="10.0.0.2 10.0.0.3 10.0.0.4"

Then run the script: 

./backup_esxi.sh
