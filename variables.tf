variable "client_id" {}
variable "client_secret" { sensitive  = true }
variable "organization_id" {}
variable "runner_name" {}
variable "stack_name" {}
variable "sample_stack_secret_name" {}
variable "azure_backend_enabled" { default = false }
variable "azure_backend_tenant_id" { default = "" }
variable "azure_backend_subscription_id" { default = ""  }
variable "azure_backend_resource_group_name" { default = ""  }
variable "azure_backend_storage_account_name" { default = ""  }
variable "azure_backend_storage_container_name" { default = ""  }