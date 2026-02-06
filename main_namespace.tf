resource "snapcd_namespace" "sample" {
  // <NOTES>
  //
  // This is a Namespace. Use this to organize your Modules
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/stack-namespace-module/#namespace
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace
  //
  // </NOTES


  name     = "sample-full"
  stack_id = data.snapcd_stack.sample_full.id
  trigger_behaviour_on_modified = "TriggerAllImmediately"
}

resource "snapcd_namespace_input_from_literal" "sample" {

  // <NOTES>
  //
  // This is a Namespace Input. Every Module within the Namespace will receive the input variable "resource_group_name" by default ever time
  // the Module is deployed. This behaviour can be toggled with the "usage_mode" flag.
  //
  // This is Namespace Input is from a literal value. Namespace Inputs can also be from "Defition" or "Secret".
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/namespace-inputs/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_literal
  //
  // </NOTES


  input_kind    = "Param"
  name          = "resource_group_name"
  literal_value = "This will be the value of 'var.myvar'!"
  namespace_id  = snapcd_namespace.sample.id
  usage_mode    = "UseByDefault"
}


resource "snapcd_namespace_input_from_definition" "azure_backend" {
  count = var.azure_backend_enabled == true ? 1 : 0
  name            = "SNAPCD_MODULE_NAME"
  definition_name = "ModuleName"
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.sample.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_extra_file" "azure_backend" {
  count = var.azure_backend_enabled == true ? 1 : 0
  file_name    = "extra_root.tf"
  contents     =  <<EOT
terraform {
  backend "azurerm" {}
}
  EOT
  namespace_id = snapcd_namespace.sample.id
  overwrite    = false
}


resource "snapcd_namespace_backend_config" "azure_backend" {
  for_each = var.azure_backend_enabled == true ? {
    tenant_id            = var.azure_backend_tenant_id
    subscription_id      = var.azure_backend_subscription_id
    resource_group_name  = var.azure_backend_resource_group_name
    storage_account_name = var.azure_backend_storage_account_name
    container_name       = var.azure_backend_storage_container_name
    key                  = "snapcd/sample-deployment/$${SNAPCD_MODULE_NAME}2.tfstate"
  } : {}

  namespace_id = snapcd_namespace.sample.id
  name         = each.key
  value        = each.value
}