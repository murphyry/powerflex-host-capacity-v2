#!/bin/bash 

########################################################################################################################################################### 
#SCRIPT VARIABLES - SET YOUR POWERFLEX MANAGER CREDENTIALS HERE
########################################################################################################################################################### 
PFXM_IP='YOUR_PFXM_IP'
PFXM_USER='YOUR_PFXM_USER'
PFXM_PASSWORD='YOUR_PFXM_USER_PASSWORD'

###########################################################################################################################################################  

#SCRIPT COLORS FOR ECHO OUTPUT  
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHT_PURPLE='\033[1;35m'
YELLOW='\033[1;33m'  
NC='\033[0m'

#START SCRIPT
echo " "
echo -e "${YELLOW}######################################################################################################## ${NC}"
echo -e "${YELLOW}# PowerFlex 4.6+ Host Capacity Script ${NC}"
echo -e "${YELLOW}# Version: 2.0.0"
echo -e "${YELLOW}# Requirements: curl, jq, and bc packages ${NC}"
echo -e "${YELLOW}# Support: No support provided, use and edit to your needs ${NC}"
echo -e "${YELLOW}# PowerFlex API Reference: https://developer.dell.com/apis/4008/versions/4.6.1/PowerFlex_REST_API.json ${NC}"
echo -e "${YELLOW}######################################################################################################## ${NC}"
echo " "

#Log into API and get a token
TOKEN=$(curl -s -k --location --request POST "https://${PFXM_IP}/rest/auth/login" --header "Accept: application/json" --header "Content-Type: application/json" --data "{\"username\": \"${PFXM_USER}\",\"password\": \"${PFXM_PASSWORD}\"}") 
ACCESS_TOKEN=$(echo "${TOKEN}" | jq -r .access_token) 


#Get the system id to use for the csv file name
SYSTEM=$(curl -k -s -X GET "https://$PFXM_IP/api/types/System/instances/" -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN")
SYSTEM_ID=$(echo $SYSTEM | jq .[].id| tr -d '"')
echo -e "${GREEN}[SUCCESS] - Connected to PowerFlex system ${SYSTEM_ID}${NC}"
echo " "
echo -e "${CYAN}[QUERYING VOLUMES]${NC}"

#Create CSV file to hold information for hosts
CSV_NAME="${SYSTEM_ID}_host_capacity_report_v2.csv"
echo "VOLUME_NAME,MAPPED_SDCS,VOLUME_PROVISIONED_GIB,VOLUME_USED_GIB,REPLICATION_ENABLED" > $CSV_NAME

#get all volume instances
VOLUMES=$(curl -k -s -X GET "https://$PFXM_IP/api/types/Volume/instances" -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN")

#extract volume IDs
VOLUME_IDS=$(echo $VOLUMES | jq .[].id)

#create an array of volume IDs
readarray -t bash_array < <(echo "$VOLUME_IDS")

#for each volume
for vol in "${bash_array[@]}"; do
  #extract the volume ID into a format that works with curl
  VOLUME_ID=$(echo $vol | tr -d '"')
  
  #get all volume information using the ID
  VOLUME_INFO=$(curl -k -s -X GET "https://$PFXM_IP/api/instances/Volume::$VOLUME_ID" -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN")
  
  #extract the mapped SDCs for the volume
  SDCS=$(echo $VOLUME_INFO | jq -r '.mappedSdcInfo')
  
  #check to make sure the volume has SDCs, and if a volume has none then skip over it 
  if [[ "$SDCS" != "null" ]]
  then
      #collect volume name
      NAME=$(echo $VOLUME_INFO | jq -r '.name')
      echo -e "${CYAN}-Volume [$NAME] FOUND - COLLECTING INFO ${NC}"  
      
      #collect vtree,and replication status
      VTREE_ID=$(echo $VOLUME_INFO | jq -r '.vtreeId')
      REP_STATE=$(echo $VOLUME_INFO | jq -r '.volumeReplicationState')
      
      #extract and format SDC names in a way that clusters wont break the CSV export
      SDC_NAMES=$(echo ${SDCS} | jq .[].sdcName | tr -d '"')
      FINAL_SDC_NAMES="\"$SDC_NAMES\""
      
      #change replication state to a more friendly label
      HAS_REPLICATION="NO"
      if [[ "$REP_STATE" != "UnmarkedForReplication" ]]
      then
        HAS_REPLICATION="YES"
      fi
      
      #collect capacity info for the volume
      VOLUME_SIZE=$(echo $VOLUME_INFO | jq .sizeInKb)
      VTREE_STATS=$(curl -k -s -X GET "https://$PFXM_IP/api/instances/VTree::$VTREE_ID/relationships/Statistics" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Accept: application/json")
      VTREE_IN_USE=$(echo $VTREE_STATS | jq -r '.netCapacityInUseInKb')
      
      #Generate GiB numebers from the KiB values
      TOTAL_SIZE_GIB=$(echo "scale=2; ${VOLUME_SIZE}/1024/1024" | bc) 
      TOTAL_IN_USE_GIB=$(echo "scale=2; ${VTREE_IN_USE}/1024/1024" | bc) 
      
      #export volume into csv
      echo "${NAME},${FINAL_SDC_NAMES},${TOTAL_SIZE_GIB},${TOTAL_IN_USE_GIB},${HAS_REPLICATION}" >> $CSV_NAME
  fi  
done

#print out the final status
echo -e "${CYAN}[QUERYING VOLUMES COMPLETE]${NC}"
echo " "
echo -e "${GREEN}######################################################################################################## ${NC}"
echo -e "${GREEN}# Script has completed. ${NC}"
echo -e "${GREEN}# CSV output can be found at $PWD$/$CSV_NAME ${NC}"
echo -e "${GREEN}######################################################################################################## ${NC}"
echo " "
