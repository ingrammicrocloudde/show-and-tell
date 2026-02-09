# Lokales Deployment testen
az deployment group create \
  --resource-group "rg-demo-dev" \
  --template-file main.bicep \
  --parameters parameters.dev.json

# What-If Analysis (zeigt was geändert wird)
az deployment group what-if \
  --resource-group "rg-demo-dev" \
  --template-file main.bicep \
  --parameters parameters.dev.json