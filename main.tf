terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.50"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "az-204-labs-rg" {
  name     = "az-204-labs-rg"
  location = "West Europe"
}

resource "azurerm_service_plan" "az-204-labs-asp1" {
  name                = "az-204-labs-asp1"
  location            = azurerm_resource_group.az-204-labs-rg.location
  resource_group_name = azurerm_resource_group.az-204-labs-rg.name
  
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "az-204-labs-app1" {
  name                = "az-204-labs-app1"
  location            = azurerm_resource_group.az-204-labs-rg.location
  resource_group_name = azurerm_resource_group.az-204-labs-rg.name
  service_plan_id     = azurerm_service_plan.az-204-labs-asp1.id

  site_config {}
}

resource "azurerm_linux_web_app_slot" "az-204-labs-app1-slot-production" {
  name                = "az-204-labs-app1-slot-production"
  app_service_id      = azurerm_linux_web_app.az-204-labs-app1.id

  site_config {}
}

resource "azurerm_linux_web_app_slot" "az-204-labs-app1-slot-development" {
  name                = "az-204-labs-app1-slot-development"
  app_service_id      = azurerm_linux_web_app.az-204-labs-app1.id

  site_config {}
}

resource "azurerm_service_plan" "az-204-labs-asp2" {
  name                = "az-204-labs-asp2"
  location            = "East US"
  resource_group_name = azurerm_resource_group.az-204-labs-rg.name
  
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "az-204-labs-app2" {
  name                = "az-204-labs-app2"
  location            = azurerm_service_plan.az-204-labs-asp2.location
  resource_group_name = azurerm_resource_group.az-204-labs-rg.name
  service_plan_id     = azurerm_service_plan.az-204-labs-asp2.id

  site_config {}
}

resource "azurerm_traffic_manager_profile" "az-204-labs-tm" {
  name = "az-204-labs-tm"
  resource_group_name = azurerm_resource_group.az-204-labs-rg.name
  profile_status = "Enabled"
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "az-204-labs-tm"
    ttl = 60
  }

  monitor_config {
    protocol = "HTTPS"
    port = 443
    path = "/"
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "az-204-labs-tm-endpoint1" {
  name = "az-204-labs-tm-endpoint1"
  profile_id = azurerm_traffic_manager_profile.az-204-labs-tm.id
  target_resource_id = azurerm_linux_web_app.az-204-labs-app1.id
  weight = 90
}

resource "azurerm_traffic_manager_azure_endpoint" "az-204-labs-tm-endpoint2" {
  name = "az-204-labs-tm-endpoint2"
  profile_id = azurerm_traffic_manager_profile.az-204-labs-tm.id
  target_resource_id = azurerm_linux_web_app.az-204-labs-app2.id
  weight = 10
}
