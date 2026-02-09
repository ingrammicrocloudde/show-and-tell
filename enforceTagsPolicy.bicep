targetScope = 'resourceGroup'

// Policy: Füge fehlende Tags automatisch hinzu
resource inheritTagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'inherit-tag-from-rg'
  properties: {
    displayName: 'Inherit tag from resource group'
    policyType: 'Custom'
    mode: 'Indexed'
    description: 'Fügt automatisch Tags von der Resource Group hinzu wenn sie fehlen'
    
    parameters: {
      tagName: {
        type: 'String'
        metadata: {
          displayName: 'Tag Name'
          description: 'Name des Tags zum Vererben'
        }
      }
    }
    
    policyRule: {
      if: {
        allOf: [
          {
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            exists: 'false'
          }
          {
            value: '[resourceGroup().tags[parameters(\'tagName\')]]'
            notEquals: ''
          }
        ]
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
          ]
          operations: [
            {
              operation: 'add'
              field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
              value: '[resourceGroup().tags[parameters(\'tagName\')]]'
            }
          ]
        }
      }
    }
  }
}