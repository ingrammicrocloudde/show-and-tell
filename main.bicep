// Parameter definieren
param location string 
param environment string 
param projectName string

// Variablen für konsistente Namensgebung
var storageAccountName = 'st${projectName}${environment}${uniqueString(resourceGroup().id)}'
var vnetName = 'vnet-${projectName}-${environment}'

// Storage Account Module aufrufen
module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    environment: environment
  }
}

// Virtual Network Module aufrufen
module network 'modules/vnet.bicep' = {
  name: 'networkDeployment'
  params: {
    vnetName: vnetName
    location: location
    environment: environment
  }
}

// Outputs für weitere Verwendung
output storageAccountId string = storage.outputs.storageAccountId
output vnetId string = network.outputs.vnetId
