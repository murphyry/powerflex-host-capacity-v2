# Overview
This is a basic shell script to total up the capacity used and what SDCs are mapped to volumes that are mapped.

The script will create a .csv file with the capacity information by volume that can then be further sorted/totaled.


![Screenshot of the script completing a run.](https://github.com/murphyry/powerflex-host-capacity-v2/blob/main/script_output_example_v2.png)

![Screenshot of the csv output from the script.](https://github.com/murphyry/powerflex-host-capacity-v2/blob/main/csv_example_v2.png)

# Directions
### Pre-reqs:
- This script makes API calls to the PowerFlex Manager API using the curl package. Check if curl is installed by running ```curl -V```
- This script parses the API call output using the jq package. Check if jq is installed by running ```jq```
- This script performs division on variables using the bc package. Check if bc is installed by running ```bc```
### Download the script:
- ```wget https://raw.githubusercontent.com/murphyry/powerflex-host-capacity/refs/heads/main/powerflex_host_capacity_v2.sh```
### Edit the script and add your PowerFlex Manager username, password, and IP address in the "SCRIPT VARIABLES" section:
- ```vim powerflex_host_capacity_v2.sh```
### Make the script executable:
- ```chmod +x powerflex_host_capacity_v2.sh```
### Run the script to generate the .csv file:
- ```./powerflex_host_capacity_v2.sh```

