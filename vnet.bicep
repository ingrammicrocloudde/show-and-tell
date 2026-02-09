param vnetName string
param location string
param environment string

var commonTags = {
  Environment: environment
  ManagedBy: 'Bicep'
  CostCenter: 'IT-Infrastructure'
}

// Unterschiedliche Address Spaces je nach Environment
var addressPrefix = environment == 'dev' ? '10.0.0.0/16' : '10.1.0.0/16'

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet-app'
        properties: {
          addressPrefix: environment == 'dev' ? '10.0.1.0/24' : '10.1.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: environment == 'dev' ? '10.0.2.0/24' : '10.1.2.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-nsg'
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
