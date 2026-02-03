resource "snapcd_module" "app" {
  name                     = "app"
  namespace_id             = snapcd_namespace.sample.id
  source_revision          = "main"
  source_url               = "https://github.com/snapcd-samples/mock-module-kubernetes-app-storefront.git"
  source_subdirectory      = ""
  runner_id                = data.snapcd_runner.sample_full.id
  auto_upgrade_enabled     = true
  auto_reconfigure_enabled = true
  auto_migrate_enabled     = false
  clean_init_enabled       = false
}

resource "snapcd_module_input_from_secret" "app_params_database_user_password" {
  // <NOTES>
  //
  // This is an Input into the above Module, taking its value from a Stack Secret. It tells Snap CD to always take the value of 
  // Secret with id data.snapcd_stack_secret.storefront_db_user_password.id and input it into variable "database_user_password"
  // on the "app" Module.
  // 
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/outputs/
  // - https://docs.snapcd.io/how-it-works/orchestration/#trigger-on-source-changed
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output
  //
  // </NOTES

  input_kind = "Param"
  module_id  = snapcd_module.app.id
  name       = "database_user_password"
  secret_id  = data.snapcd_stack_secret.storefront_db_user_password.id
  type       = "String"
}


resource "snapcd_module_input_from_literal" "app_params_notstring" {
    // <NOTES>
  //
  // This is another "literal" Input into the above Module. Note that it uses a type "NotString". This is relevant when you need to 
  // pass in values like numbers as terraform variables.
  // "NotString" means: replicas=3
  // "String"    means: replicas="3"
  // 
  // </NOTES

  for_each = {
    replicas = 3
  }
  input_kind    = "Param"
  module_id     = snapcd_module.app.id
  name          = each.key
  literal_value = each.value
  type          = "NotString"
}


resource "snapcd_module_input_from_literal" "app_params_string" {
  for_each = {
    app_url = "https://storefront.demo.com"
    database_user_name = "some-user"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.app.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}



resource "snapcd_module_input_from_output_set" "app_params_from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.app.id
  name             = "from_cluster"
  output_module_id = snapcd_module.cluster.id
}


resource "snapcd_module_input_from_output_set" "app_params_from_database" {
  input_kind       = "Param"
  module_id        = snapcd_module.app.id
  name             = "from_database"
  output_module_id = snapcd_module.database.id
}

