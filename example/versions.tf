terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.35.1"
    }
    azapi = {
      source = "Azure/azapi"
      version = "~> 2.2.0"
    }
  }
  required_version = ">= 1.9.0"
}
