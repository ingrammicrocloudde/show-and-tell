targetScope = 'subscription'

// Policy Definition: Require specific tags
resource tagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-tags-policy'
  properties: {
    displayName: 'Require specific tags on resources'
    policyType: 'Custom'
    mode: 'Indexed'
    description: 'Erzwingt dass bestimmte Tags auf Ressourcen gesetzt sind'
    
    parameters: {
      tagName: {
        type: 'String'
        metadata: {
          displayName: 'Tag Name'
          description: 'Name des erforderlichen Tags'
        }
      }
    }
    
    policyRule: {
      if: {
        field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
        exists: 'false'
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

// Policy Assignment
resource tagPolicyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: 'enforce-environment-tag'
  properties: {
    displayName: 'Enforce Environment Tag'
    description: 'Alle Ressourcen müssen ein Environment-Tag haben'
    policyDefinitionId: tagPolicy.id
    parameters: {
      tagName: {
        value: 'Environment'
      }
    }
  }
}

// Initiative (Policy Set) mit mehreren Policies
resource tagInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'tagging-initiative'
  properties: {
    displayName: 'Corporate Tagging Standards'
    policyType: 'Custom'
    description: 'Sammlung von Tag-Policies für Corporate Governance'
    
    policyDefinitions: [
      {
        policyDefinitionId: tagPolicy.id
        parameters: {
          tagName: {
            value: 'Environment'
          }
        }
      }
      {
        policyDefinitionId: tagPolicy.id
        parameters: {
          tagName: {
            value: 'CostCenter'
          }
        }
      }
      {
        policyDefinitionId: tagPolicy.id
        parameters: {
          tagName: {
            value: 'Owner'
          }
        }
      }
    ]
  }
}