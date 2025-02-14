// Parameters
param containerAppName string
param location string
param managedEnvironmentName string
param acrName string
param imageName string
param acrPassword string
param storageAccountName string
param storageAccountKey string
param fileShareName string
param targetPorts array = [8080, 8065, 8075] // Multiple target ports

// Reference the existing Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: managedEnvironmentName
}

// Create a storage link for Azure Files in the Managed Environment
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-05-01' = {
  parent: managedEnvironment
  name: '${storageAccountName}-link' // Ensure the name is unique
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: fileShareName
      accessMode: 'ReadWrite' // Or 'ReadOnly' based on your needs
    }
  }
}

// Deploy the Container App with ingress configuration
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      registries: [
        {
          server: '${acrName}.azurecr.io'
          username: acrName
          passwordSecretRef: 'acr-password' // Secret name
        }
      ]
      ingress: {
        external: true // Set to true to expose it externally
        targetPorts: targetPorts // Exposing multiple ports
        transport: 'tcp' // TCP ingress traffic
      }
      secrets: [
        {
          name: 'acr-password' // Secret name for ACR password
          value: acrPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrName}.azurecr.io/${imageName}:latest' // Image path
          resources: {
            cpu: 2
            memory: '4Gi' // Resources for the container
          }
          env: [ // Environment variables
            {
              name: 'ACCEPT_GENERAL_CONDITIONS'
              value: 'yes'
            },
            {
              name: 'MY_ENV_VARIABLE_1'
              value: 'value1' // Replace with your actual values
            },
            {
              name: 'MY_ENV_VARIABLE_2'
              value: 'value2' // Replace with your actual values
            }
            // Add other environment variables as needed
          ]
          volumeMounts: [
            {
              volumeName: '${storageAccountName}-volume'
              mountPath: '/opt/Axway/apigateway/conf/licenses'
            }
          ]
        }
      ]
      volumes: [
        {
          name: '${storageAccountName}-volume'
          storageType: 'AzureFile'
          storageName: '${storageAccountName}-link' // Storage link
        }
      ]
    }
    scale: {
      minReplicas: 1
      maxReplicas: 3
    }
  }
}
