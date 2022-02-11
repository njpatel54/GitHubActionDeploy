param location string
param nsgName string = 'vmNSG-Test'
param vNetName string
param tagValues object

@secure()
param adminLogin string

@secure()
param adminPassword string

param vmSize string = 'Standard_D2_v3'

@allowed([
    '2019-Datacenter'
    '2016-Datacenter'
    '2016-Datacenter-Server-Core'
    '2016-Datacenter-Server-Core-smalldisk'
    '2016-Datacenter-smalldisk'
    '2016-Datacenter-with-Containers'
    '2016-Nano-Server'
  ])
param osVersion string = '2019-Datacenter'

var VMs = [
    {
      name: 'azurevm10'
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      disks: [
        32
        64
        128
      ]
    }
    {
      name: 'azurevm11'
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      disks: [
        32
        64
      ]
    }
]

var inboundRules = [
      {
        name: 'default-allow-3389'
        priority: 1000
        access: 'Allow'
        direction: 'Inbound'
        destinationPortRange: '3389'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
      }
]

resource vmPIPs 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for VM in VMs: {
  name: '${VM.name}-pip'
  location: location
  tags: tagValues
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: VM.name
    }
  }
}]

resource vmNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgName
  location: location
  tags: tagValues
  properties: {
    securityRules: [for rule in inboundRules: {
        name: rule.name
        properties: {
          priority: rule.priority
          access: rule.access
          direction: rule.direction
          destinationPortRange: rule.destinationPortRange
          protocol: rule.protocol
          sourcePortRange: rule.sourcePortRange
          sourceAddressPrefix: rule.sourceAddressPrefix
          destinationAddressPrefix: rule.destinationAddressPrefix
        }
      }]
  }
}

resource prodNICs 'Microsoft.Network/networkInterfaces@2020-06-01' = [for VM in VMs: {
  name: '${VM.name}-nic'
  location: location
  tags: tagValues
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
            id: resourceId('Microsoft.Network/publicIPAddresses/', '${VM.name}-pip')
         }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'sales-subnet')
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: vmNSG.id
    }
  }
}]

resource prodVMs 'Microsoft.Compute/virtualMachines@2020-06-01' = [for VM in VMs: {
  name: VM.name
  location: location
  tags: tagValues
  dependsOn: [
    vmPIPs
    prodNICs
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: VM.name
      adminUsername: adminLogin
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: VM.publisher
        offer: VM.offer
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        name: '${VM.name}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [ for (disk, i) in VM.disks: {

          name: '${VM.name}-datadisk-${disk}'
          diskSizeGB: disk
          lun: i
          createOption: 'Empty'
          
      }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces/', '${VM.name}-nic')
        }
      ]
    }
  }
}]
