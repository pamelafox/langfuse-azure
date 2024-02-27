param name string
@secure()
param databasePassword string
param location string = resourceGroup().location

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var containerAppName = '${name}-container-app'
var dbName = '${name}-${resourceToken}-db'

var databaseUsername = 'admin${toLower(uniqueString(subscription().id, name, location))}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${name}-workspace'
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


resource containerEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${name}-container-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

resource containerApp 'Microsoft.App/containerapps@2022-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          image: 'ghcr.io/langfuse/langfuse:latest'
          name: containerAppName
          env: [
            {
              name: 'DATABASE_URL'
              value: 'postgres://${databaseUsername}:${databasePassword}@${dbName}.postgres.database.azure.com:5432/langfuse'
            }
            {
              name: 'NEXTAUTH_URL'
              value: 'https://${containerAppName}.azurewebsites.net'
            }
            {
              name: 'NEXTAUTH_SECRET'
              value: 'TODO'
            }
            {
              name: 'SALT'
              value: 'TODO'
            }
          ]
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        maxReplicas: 10
      }
    }
  }
}


resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-01-20-preview' = {
  name: dbName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: databaseUsername
    administratorLoginPassword: databasePassword
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
    }
    highAvailability: {
      mode: 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Disabled'
      dayOfWeek: 0
      startHour: 0
      startMinute: 0
    }
  }
}

resource postgresServer_datase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-01-20-preview' = {
  parent: postgresServer
  name: 'langfuse'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

resource postgresServer_AllowAllWindowsAzureIps 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-01-20-preview' = {
  parent: postgresServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output webUrl string = containerApp.properties.latestRevisionFqdn
