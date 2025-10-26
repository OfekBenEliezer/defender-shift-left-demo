@description('Location for all resources')
param location string = resourceGroup().location

@description('VM name')
param vmName string = 'demo-vm'

@description('Admin username - insecure demo value')
param adminUsername string = 'azureuser'

@description('Admin password - INSECURE: hardcoded for demo only')
param adminPassword string = 'P@ssword123!' // demo only - do NOT use in production

@description('VM size')
param vmSize string = 'Standard_B1s'

@description('Storage account name (must be unique)')
param storageAccountName string = 'demostorage${uniqueString(resourceGroup().id)}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Anywhere'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '0.0.0.0/0'     // INSECURE - allows RDP from anywhere
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource nicWithNsg 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: nic.name
  location: location
  properties: union(nic.properties, {
    networkSecurityGroup: {
      id: nsg.id
    }
  })
  dependsOn: [
    nic
    nsg
  ]
}

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: toLower(storageAccountName)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true    // INSECURE - public blob access enabled
    minimumTlsVersion: 'TLS1_2'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword   // INSECURE - hardcoded password in template
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicWithNsg.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
  dependsOn: [
    nicWithNsg
    storage
  ]
}

output vmId string = vm.id
output publicIp string = publicIP.properties.ipAddress
output storageAccountNameOut string = storage.name
