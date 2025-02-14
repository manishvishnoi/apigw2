// Parameters
param containerAppName string
param location string
param existingContainerAppEnvironmentName string
param storageAccountName string
param dockerImage string
param fileShareName string
param storageAccountKey string // Key passed from the pipeline as a parameter

// Reference existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Reference existing Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: existingContainerAppEnvironmentName
}

// Create a storage link for Azure Files in the Managed Environment
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-04-01-preview' = {
  parent: managedEnvironment
  name: '${storageAccountName}-link' // Make sure the name matches the link reference
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: fileShareName
      accessMode: 'ReadWrite' // Or 'ReadOnly' based on your needs
    }
  }
}

// Deploy the Container App
resource containerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: managedEnvironment.id


    configuration: {
      secrets: [
        {
          name: 'storageaccountkey'
          value: storageAccountKey
        }
      ]
	  
	      // Configure TCP Ingress
      ingress: {
       external: true // Allow external traffic
       targetPort: 8080 // Default target port
       transport: 'tcp' // Set the ingress type to TCP
       exposedPorts: [
        {
          port: 8080 // Expose port 8080
          external: true // Allow external access
        }
        {
          port: 8065 // Expose port 8065
          external: true // Allow external access
        }
        {
          port: 8075 // Expose port 8075
          external: true // Allow external access
        }
      ]
       traffic: [
        {
          weight: 100 // All traffic goes to this revision
          latestRevision: true
        }
      ]
     }
    }

    template: {
      containers: [
        {
          name: containerAppName
          image: dockerImage
          env: [{ name: 'ACCEPT_GENERAL_CONDITIONS', value: 'yes' },{ name: 'EMT_ANM_HOSTS', value: 'anm:8090' },{ name: 'CASS_HOST', value: 'casshost1' },{ name: 'EMT_TRACE_LEVEL', value: 'DEBUG' }     
          ]
          volumeMounts: [
            {
              volumeName: '${storageAccountName}-volume' // Volume name
              mountPath: '/opt/Axway/apigateway/conf/licenses'
            }
          ]
        }
      ]
      volumes: [
        {
          name: '${storageAccountName}-volume' // Ensure this matches the volume reference in container
          storageType: 'AzureFile'
          storageName: '${storageAccountName}-link' // Ensure the storage link name matches
        }
      ]
    }
  }
}
