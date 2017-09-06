---
services: resources
platforms: ruby
author: vishrutshah
---

# Manage resources using Managed Service Identity using Ruby

This sample demonstrates how to manage Azure resources via Managed Service Identity using the Ruby SDK.

**On this page**

- [Create an Azure VM with MSI extension](#pre-requisite)
- [Run this sample](#run)
- [What is example.rb doing?](#example)
    - [Create an MSI Token Provider](#msi)
    - [Create a resource client](#resource-client)
    - [Create an Azure Vault](#create-vault)
    - [Delete an Azure vault](#delete-vault)

<a id="pre-requisite"></a>
## Create an Azure VM with MSI extension

[Azure Compute VM with MSI](https://github.com/Azure-Samples/compute-ruby-msi-vm)

<a id="run"></a>
## Run this sample

1. log in to the above Azure virtual machine which has MSI service running and then follow the steps on that VM.

1. If you don't already have it, [install Ruby and the Ruby DevKit](https://www.ruby-lang.org/en/documentation/installation/).

1. If you don't have bundler, install it.

    ```
    gem install bundler
    ```

1. Clone the repository.

    ```
    git clone https://github.com/Azure-Samples/resources-ruby-manage-resources-with-msi.git
    ```

1. Install the dependencies using bundle.

    ```
    cd resources-ruby-manage-resources-with-msi
    bundle install
    ```

1. Set the following environment variables using the information from the service principle that you created.

    ```
    export AZURE_TENANT_ID={your tenant id}
    export AZURE_SUBSCRIPTION_ID={your subscription id}
    export RESOURCE_GROUP_NAME={name of the resource group}    
    ```

    > [AZURE.NOTE] On Windows, use `set` instead of `export`.

1. Run the sample.

    ```
    bundle exec ruby example.rb
    ```

<a id="example"></a>
## What is example.rb doing?
<a id="msi"></a>
### Create an MSI Token Provider
```ruby
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111'
tenant_id = ENV['AZURE_TENANT_ID']
resource_group_name = ENV['RESOURCE_GROUP_NAME']
port = ENV['MSI_PORT'] || 50342 # If not provided then we assume the default port
```
```ruby
# Create Managed Service Identity as the token provider
provider = MsRestAzure::MSITokenProvider.new(port)
credentials = MsRest::TokenCredentials.new(provider)
```

<a id="resource-client"></a>
### Create a resource client
```ruby
client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
client.subscription_id = subscription_id
```
<a id="create-vault"></a>
### Create an Azure Vault

```ruby
puts 'Creating key vault account with MSI Identity...'
key_vault_params = Azure::ARM::Resources::Models::GenericResource.new.tap do |rg|
  rg.location = WEST_US
  rg.properties = {
      sku: { family: 'A', name: 'standard' },
      tenantId: tenant_id,
      accessPolicies: [],
      enabledForDeployment: true,
      enabledForTemplateDeployment: true,
      enabledForDiskEncryption: true
  }
end
```

<a id="delete-vault"></a>
### Delete an Azure vault

```ruby
client.resources.delete(resource_group_name,
                          'Microsoft.KeyVault',
                          '',
                          'vaults',
                          KEY_VAULT_NAME,
                          '2015-06-01')
```
