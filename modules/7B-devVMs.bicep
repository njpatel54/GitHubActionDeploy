param location string
param osVersion string = '2019-Datacenter'
param vmSize string = 'Standard_D2_v3'
param nsgName string = 'vmNSG-Test'
param devHubVNetName string = 'Development-VNet'
param itSpokeVNetName string = 'IT-VNet'
param devBastionHostName string = 'Dev-Bastion-Host'
param devVMExtensionsName string = 'Initial-Config'
param devFileUris string = 'https://csu100329186de80080.blob.core.usgovcloudapi.net/test/start.ps1'
param commandToExecute string = 'powershell.exe -ExecutionPolicy Unrestricted -File start.ps1'

@secure()
param adminLogin string

@secure()
param adminPassword string

var VMs = [
  'dev-vm-01'
  'it-vm-01'
]

resource vmPIPs 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for VM in VMs: {
  name: '${VM}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: VM
    }
  }
}]

resource vmNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource devNICs 'Microsoft.Network/networkInterfaces@2020-06-01' = [for VM in VMs: {
  name: '${VM}-nic'
  location: location
  dependsOn: [
    vmPIPs
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses/', '${VM}-pip')
          }
          subnet: {
            id: (VM == 'dev-vm-01') ? resourceId('Microsoft.Network/virtualNetworks/subnets', devHubVNetName, 'default') : resourceId('Microsoft.Network/virtualNetworks/subnets', itSpokeVNetName, 'it-subnet')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: vmNSG.id
    }
  }
}]

resource devVMs 'Microsoft.Compute/virtualMachines@2020-06-01' = [for VM in VMs: {
  name: VM
  location: location
  dependsOn: [
    vmPIPs
    devNICs
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: VM
      adminUsername: adminLogin
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${VM}-nic')
        }
      ]
    }
  }
}]

resource dscExtensions 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = [for VM in VMs: {
  name: '${VM}/${devVMExtensionsName}'
  location: location
  dependsOn: [
    devVMs
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        devFileUris
      ]
    commandToExecute: commandToExecute
    }
  }
}]

resource devBastionHostPIP 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: '${devBastionHostName}-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource devBastionHost 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: devBastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', devHubVNetName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: devBastionHostPIP.id
          }
        }
      }
    ]
  }
}


output devVMPrivateIP string = devNICs[0].properties.ipConfigurations[0].properties.privateIPAddress
output itVMPrivateIP string = devNICs[1].properties.ipConfigurations[0].properties.privateIPAddress
