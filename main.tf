module "sample" {
  source = "./module"
  stack_name = var.stack_name
  runner_name = var.runner_name
  sample_stack_secret_name = var.sample_stack_secret_name
  namespace_name = var.namespace_name
}

