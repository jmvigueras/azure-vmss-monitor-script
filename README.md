# Azure Virtual Machine Scale Set (VMSS) monitor script

Bash script to monitor VMSS instances

## Use
Update script with your Resource Group name and VMSS name.

```sh
RESOURCE_GROUP="<YOUR_RG_NAME>"
VMSS_NAME="<YOUR_VMSS_NAME>"
```

JSON Output: 
```sh
{
  "instances": [
    {
      "instance_name": "WebSRV_1d228fdd",
      "private_ip": "172.16.49.5",
      "cpu_average_5min": "0.67"
    },
    {
      "instance_name": "WebSRV_b54d95c7",
      "private_ip": "172.16.49.4",
      "cpu_average_5min": "0.69"
    }
  ]
}
```

It is necessary to have Azure CLI tools intaled and logged to Azure. 

## Support
This a personal repository with goal of testing and demo Fortinet solutions on the Cloud. No support is provided and must be used by your own responsability. Cloud Providers will charge for this deployments, please take it in count before proceed.

