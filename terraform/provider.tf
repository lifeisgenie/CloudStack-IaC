terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
}

variable "api_key" {
  description = "CloudStack API Key"
  type        = string
}

variable "secret_key" {
  description = "CloudStack Secret Key"
  type        = string
}

provider "cloudstack" {
  api_url    = "https://dku.kloud.zone/client/api"
  api_key    = var.api_key
  secret_key = var.secret_key
}