resource "snapcd_module" "cluster" {
  name                     = "cluster"
  namespace_id             = snapcd_namespace.sample.id
  source_revision          = "main"
  source_url               = "https://github.com/snapcd-samples/mock-module-kubernetes-cluster.git"
  source_subdirectory      = ""
  runner_id                = data.snapcd_runner.sample_full.id
  auto_upgrade_enabled     = true
  auto_reconfigure_enabled = true
  auto_migrate_enabled     = false
  clean_init_enabled       = false
}

resource "snapcd_module_input_from_literal" "cluster_params" {
  for_each = {
    cluster_name       = "demo-cluster"
    kubernetes_version = "1.28"
    node_instance_type = "m5.large"
    desired_capacity   = "3"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.cluster.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "cluster_params" {
  input_kind       = "Param"
  module_id        = snapcd_module.cluster.id
  name             = "from_vpc"
  output_module_id = snapcd_module.vpc.id
}