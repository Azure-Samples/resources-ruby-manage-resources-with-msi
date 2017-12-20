#!/usr/bin/env ruby

require 'azure_mgmt_resources'
require 'dotenv'

Dotenv.load!(File.join(__dir__, './.env'))

LOCATION = 'westcentralus'
KEY_VAULT_NAME = 'sampleVault8976'

# This script expects that the following environment vars are set:
#
# AZURE_TENANT_ID: with your Azure Active Directory tenant id or domain
# AZURE_SUBSCRIPTION_ID: with your Azure Subscription Id
# RESOURCE_GROUP_NAME: Name of the Azure resource group to create resource in where Managed Service Identity has enough permissions
#
def run_example
  #
  # Create the Resource Manager Client with an Managed Service Identity token provider
  #
  MsRest.use_ssl_cert
  subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
  tenant_id = ENV['AZURE_TENANT_ID']
  resource_group_name = ENV['RESOURCE_GROUP_NAME']

  port = ENV['MSI_PORT'] || 50342 # If not provided then we assume the default port
  settings = MsRestAzure::ActiveDirectoryServiceSettings.get_azure_settings

  # Create System Assigned MSI token provider
  provider = MsRestAzure::MSITokenProvider.new

  # The below code shows options to create MSI token provider for User Assigned identity.
  # Please uncomment the desired line to run this sample and obtain the appropriate token provider.
  #
  # # Create User Assigned MSI token provider using client_id
  # provider = MsRestAzure::MSITokenProvider.new(port, settings,  {:client_id => '00000000-0000-0000-0000-000000000000' })
  #
  # # Create User Assigned MSI token provider using object_id
  # provider = MsRestAzure::MSITokenProvider.new(port, settings,  {:object_id => '00000000-0000-0000-0000-000000000000' })
  #
  # # Create User Assigned MSI token provider using msi_res_id
  # provider = MsRestAzure::MSITokenProvider.new(port, settings,  {:msi_res_id => '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/msiname'})


  credentials = MsRest::TokenCredentials.new(provider)

  # Create a resource client
  client = Azure::Resources::Mgmt::V2017_05_10::ResourceManagementClient.new(credentials)
  client.subscription_id = subscription_id

  # Create a Key Vault in the Resource Group
  puts 'Creating key vault account with MSI Identity...'
  key_vault_params = Azure::Resources::Mgmt::V2017_05_10::Models::GenericResource.new.tap do |rg|
    rg.location = LOCATION
    rg.properties = {
        sku: { family: 'A', name: 'standard' },
        tenantId: tenant_id,
        accessPolicies: [],
        enabledForDeployment: true,
        enabledForTemplateDeployment: true,
        enabledForDiskEncryption: true
    }
  end

  puts JSON.pretty_generate(client.resources.create_or_update(resource_group_name,
                                                              'Microsoft.KeyVault',
                                                              '',
                                                              'vaults', KEY_VAULT_NAME,
                                                              '2015-06-01',
                                                              key_vault_params).properties)  + "\n\n"

  puts 'Now that we have created a Key Vault, lets delete it.'
  puts 'Press any key to continue'
  gets
  puts 'Deleting key vault account with MSI Identity...'
  client.resources.delete(resource_group_name,
                          'Microsoft.KeyVault',
                          '',
                          'vaults',
                          KEY_VAULT_NAME,
                          '2015-06-01')

  puts 'Thanks for learning about managing resources via Managed Service Identity.'
end

if $0 == __FILE__
  run_example
end
