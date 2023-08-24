provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-functionapp-rg"
  location = var.region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}functionvnet"
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  dns_servers = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "subnetFunctionApp" {
  name                 = "${var.prefix}functionsubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "subnetStorage" {
  name                 = "${var.prefix}storagesubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_private_dns_zone" "dnsZoneBlob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone" "dnsZoneFile" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_storage_account" "functionAppStorage" {
  name                            = "${var.prefix}funcaoostore"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = var.region
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = "false"
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules  = ["76.187.84.121"]
    virtual_network_subnet_ids = [azurerm_subnet.subnetStorage.id, azurerm_subnet.subnetFunctionApp.id]
  }
}


resource "azurerm_storage_share" "example" {
  name                 = "function-content-share"
  storage_account_name = azurerm_storage_account.functionAppStorage.name
  quota                = 50
}


resource "azurerm_private_endpoint" "fileEndpoint" {
  name                = "${var.prefix}-fileEndpoint"
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.subnetStorage.id

  private_dns_zone_group {
    name                 = "${var.prefix}-dns-zone-group-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsZoneFile.id]
  }

  private_service_connection {
    name                           = "${var.prefix}-privateFileSvcCon"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.functionAppStorage.id
    subresource_names              = ["file"]
  }
}

resource "azurerm_private_endpoint" "blobEndpoint" {
  name                = "${var.prefix}-blobEndpoint"
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.subnetStorage.id

  private_dns_zone_group {
    name                 = "${var.prefix}-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsZoneBlob.id]
  }

  private_service_connection {
    name                           = "${var.prefix}-privateBlobSvcCon"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.functionAppStorage.id
    subresource_names              = ["blob"]
  }
}

resource "azurerm_service_plan" "adf-functions-premium-asp" {
  name                = "${var.prefix}-function-asp"
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "EP1"
}

resource "azurerm_linux_function_app" "functionapp" {

  name                       = "${var.prefix}funcexample"
  location                   = var.region
  resource_group_name        = azurerm_resource_group.example.name
  service_plan_id            = azurerm_service_plan.adf-functions-premium-asp.id
  storage_account_name       = azurerm_storage_account.functionAppStorage.name
  storage_account_access_key = azurerm_storage_account.functionAppStorage.primary_access_key
  virtual_network_subnet_id  = azurerm_subnet.subnetFunctionApp.id
  https_only                 = true
  site_config {
    application_stack {
      python_version = "3.9"
    }
    elastic_instance_minimum = 1
  }
  app_settings = {
    "WEBSITE_CONTENTOVERVNET" = "1",
    "WEBSITE_CONTENTSHARE" = azurerm_storage_share.example.name,
    "WEBSITE_VNET_ROUTE_ALL"                   = "1",
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.functionAppStorage.primary_connection_string,
    "FUNCTIONS_WORKER_RUNTIME"                 = "python"
    "WEBSITE_DNS_SEVER"                        = "168.63.129.16"
  }
}
