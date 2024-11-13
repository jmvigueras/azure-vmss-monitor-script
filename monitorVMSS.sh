###############################################################################
#!/bin/bash
#
# Script de monitorización de grupo de autoescalado en Azure (VMSS)
#
# # Uso:
#   Azure CLI debe estar instalada y autenticada contra Azure "az login"
# 
# Aviso:
# Este script se proporciona sin ningún tipo de garantia o soporte. 
#
# Author: jmvigueras
# Date: 13-11-24
###############################################################################

# Requered variables
RESOURCE_GROUP="<YOUR_RG_NAME>"
VMSS_NAME="<YOUR_VMSS_NAME>"

# Get Suscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
# Set the metric to monitor (Percentage CPU)
METRIC="Percentage CPU"

# Set the timespan for the last 5 minutes
end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
start_time=$(date -u -v -5M +"%Y-%m-%dT%H:%M:%SZ")

# List all VM instances in the VMSS and retrieve their IDs and names
instances=$(az vmss list-instances --resource-group "$RESOURCE_GROUP" --name "$VMSS_NAME" --query "[].{instanceId:id, vmId:instanceId}" -o json)
# Get subnet ID for the instances VMSSS
subnet_id=$(az vmss show --resource-group "$RESOURCE_GROUP" --name "$VMSS_NAME" --query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id" -o tsv)
# Get the NICs in the subnet
nic_ids=$(az network nic list --resource-group "$RESOURCE_GROUP" --query "[?ipConfigurations[0].subnet.id=='$subnet_id'].{id:id, name:ipConfigurations[0].name, vmId:virtualMachine.id}" -o json)

# Prepare JSON output
output="{\"instances\":["

# Loop through each instance to get private IPs
for instance in $(echo "$instances" | jq -c '.[]'); do
    instance_id=$(echo "$instance" | jq -r '.instanceId')
    instance_vmId=$(echo "$instance" | jq -r '.vmId')

    # Construct the resource ID for the virtual machine (individual instance)
    vm_resource_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/$instance_vmId"

    # Get the metric data using the Azure CLI
    data=$(az monitor metrics list --resource $vm_resource_id --metric "$METRIC" --start-time "$start_time" --end-time "$end_time" --interval PT1M --query "value[0].timeseries[].data[].average" -o tsv)

    # Calculate the average of the CPU usage in the last 5 minutes
    average_cpu=0
    count=0

    # Loop through the data and sum the values
    for value in $data; do
      average_cpu=$(echo "$average_cpu + $value" | bc)
      count=$((count + 1))
    done

    # Calculate the final average
    if [ $count -gt 0 ]; then
        final_average=$(echo "$average_cpu / $count" | bc -l)
        # Round the result to 2 decimal places
        rounded_average=$(printf "%.2f" $final_average)
    fi

    # Initialize private_ip as N/A
    private_ip="N/A"
    
    # Search for the NIC that corresponds to the instance and get its private IP
    for nic in $(echo "$nic_ids" | jq -c '.[]'); do
        nic_id=$(echo "$nic" | jq -r '.id')
        nic_name=$(echo "$nic" | jq -r '.name')
        vm_id=$(echo "$nic" | jq -r '.vmId')

        # Check if this NIC is linked to the current instance based on vm_id
        if [[ "$vm_id" == *"$instance_vmId"* ]]; then
            # Get the NIC details to retrieve private IP
            private_ip=$(az network nic show --ids "$nic_id" --query "ipConfigurations[0].privateIpAddress" -o tsv)
            break
        fi
    done

    # Append instance data to JSON output
    output+="{\"instance_name\": \"$instance_vmId\", \"private_ip\": \"$private_ip\", \"cpu_average_5min\": \"$rounded_average\"},"
done

# Finalize JSON output
output=${output%,} # Remove trailing comma
output+="]}"

# Print JSON output
echo "$output" | jq .







