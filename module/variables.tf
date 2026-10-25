variable "runner_name" {}
variable "agent_name" {}
variable "stack_name" {}
variable "sample_stack_secret_name" {}
variable "namespace_name" { default = "my-sample-namespace" }
variable "snapcd_server_url_from_runner" {}
variable "organization_id" {}
variable "scoped_runner_name" { default = "sample-scoped-runner" }
variable "scoped_namespace_name" { default = "sample-scoped-namespace" }
