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


resource "azurerm_resource_group" "az204labs-rg" {
  name     = "az204labs-rg"
  location = "West Europe"
}

resource "azurerm_service_plan" "az204labs-asp-web-westeu" {
  name                = "az204labs-asp-web-westeu"
  location            = azurerm_resource_group.az204labs-rg.location
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "az204labs-app-web-westeu" {
  name                = "az204labs-app-web-westeu"
  location            = azurerm_resource_group.az204labs-rg.location
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  service_plan_id     = azurerm_service_plan.az204labs-asp-web-westeu.id

  site_config {}
}

resource "azurerm_linux_web_app_slot" "web-prod" {
  name                = "web-prod"
  app_service_id      = azurerm_linux_web_app.az204labs-app-web-westeu.id

  site_config {}
}

resource "azurerm_linux_web_app_slot" "web-dev" {
  name                = "web-dev"
  app_service_id      = azurerm_linux_web_app.az204labs-app-web-westeu.id

  site_config {}
}

resource "azurerm_service_plan" "az204labs-asp-web-eastus" {
  name                = "az204labs-asp-web-eastus"
  location            = "East US"
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "az204labs-app-web-eastus" {
  name                = "az204labs-app-web-eastus"
  location            = azurerm_service_plan.az204labs-asp-web-eastus.location
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  service_plan_id     = azurerm_service_plan.az204labs-asp-web-eastus.id

  site_config {}
}

resource "azurerm_traffic_manager_profile" "az204labs-tm" {
  name = "az204labs-tm"
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  profile_status = "Enabled"
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "az204labs-tm"
    ttl = 60
  }

  monitor_config {
    protocol = "HTTPS"
    port = 443
    path = "/"
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "az204labs-tm-endpoint-asp-westeu" {
  name = "az204labs-tm-endpoint-asp-westeu"
  profile_id = azurerm_traffic_manager_profile.az204labs-tm.id
  target_resource_id = azurerm_linux_web_app.az204labs-app-web-westeu.id
  weight = 90
}

resource "azurerm_traffic_manager_azure_endpoint" "az204labs-tm-endpoint-asp-eastus" {
  name = "az204labs-tm-endpoint-asp-eastus"
  profile_id = azurerm_traffic_manager_profile.az204labs-tm.id
  target_resource_id = azurerm_linux_web_app.az204labs-app-web-eastus.id
  weight = 10
}


resource "azurerm_service_plan" "az204labs-asp-api-westeu" {
  name                = "az204labs-asp-api-westeu"
  location            = azurerm_resource_group.az204labs-rg.location
  resource_group_name = azurerm_resource_group.az204labs-rg.name

  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "az204labs-app-api-westeu" {
  name                = "az204labs-app-api-westeu"
  location            = azurerm_service_plan.az204labs-asp-api-westeu.location
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  service_plan_id     = azurerm_service_plan.az204labs-asp-api-westeu.id

  site_config {}
}

resource "azurerm_monitor_autoscale_setting" "az204labs-app-api-westeu-autoscale" {
  name                = "az204labs-app-api-westeu-autoscale"
  resource_group_name = azurerm_resource_group.az204labs-rg.name
  location            = azurerm_resource_group.az204labs-rg.location
  target_resource_id  = azurerm_service_plan.az204labs-asp-api-westeu.id
  
  
  profile {
    name = "autoscale"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.az204labs-asp-api-westeu.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.az204labs-asp-api-westeu.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}

resource "azurerm_mssql_server" "az204labs-sql" {
  name                         = "az204labs-sql"
  resource_group_name          = azurerm_resource_group.az204labs-rg.name
  location                     = azurerm_resource_group.az204labs-rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234"
}

