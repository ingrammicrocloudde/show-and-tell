param location string = resourceGroup().location
param vmssName string = 'vmss-webapp'
param environment string = 'prod'

var autoScaleProfileName = 'Auto-Scale-Profile'

// Virtual Machine Scale Set
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-03-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'Standard'
    capacity: 2 // Mindestanzahl
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: 'azureuser'
        adminPassword: 'P@ssw0rd1234!' // In Produktion: Key Vault verwenden!
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-config'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-prod', 'subnet-app')
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb-webapp', 'backend-pool')
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// Autoscale Settings
resource autoScaleSettings 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: '${vmssName}-autoscale'
  location: location
  properties: {
    enabled: true
    targetResourceUri: vmss.id
    
    profiles: [
      {
        name: autoScaleProfileName
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          // Scale OUT bei hoher CPU
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 75
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale IN bei niedriger CPU
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 25
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
          // Scale OUT bei hohem Memory Druck
          {
            metricTrigger: {
              metricName: 'Available Memory Bytes'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 1073741824 // 1 GB
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          // Scale basierend auf HTTP Queue Length
          {
            metricTrigger: {
              metricName: 'HttpQueueLength'
              metricResourceUri: resourceId('Microsoft.Web/serverfarms', 'asp-webapp')
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 10
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '2' // Schnelleres Scale-out bei Queue
              cooldown: 'PT3M'
            }
          }
        ]
      }
      // Zeitbasiertes Profil für bekannte Spitzenzeiten
      {
        name: 'Business-Hours-Peak'
        capacity: {
          minimum: '4'
          maximum: '10'
          default: '4'
        }
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'W. Europe Standard Time'
            days: [
              'Monday'
              'Tuesday'
              'Wednesday'
              'Thursday'
              'Friday'
            ]
            hours: [
              9
            ]
            minutes: [
              0
            ]
          }
        }
        rules: [] // Gleiche Rules wie oben, hier vereinfacht weggelassen
      }
      // Niedrige Last am Wochenende
      {
        name: 'Weekend-Low'
        capacity: {
          minimum: '1'
          maximum: '3'
          default: '1'
        }
        recurrence: {
          frequency: 'Week'
          schedule: {
            timeZone: 'W. Europe Standard Time'
            days: [
              'Saturday'
              'Sunday'
            ]
            hours: [
              0
            ]
            minutes: [
              0
            ]
          }
        }
        rules: []
      }
    ]
    
    notifications: [
      {
        operation: 'Scale'
        email: {
          sendToSubscriptionAdministrator: false
          sendToSubscriptionCoAdministrators: false
          customEmails: [
            'cloudops@company.com'
          ]
        }
        webhooks: []
      }
    ]
  }
}