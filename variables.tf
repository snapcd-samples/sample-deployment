// The default variables below are set to work out of the box with the pre-configured "snapcd-selfhosted-deployment-docker"

//// Needed to init provider
variable "client_id" {
  default = "default"
}
variable "client_secret" {
  default   = "default"
  sensitive = true
}
variable "organization_id" {
  default = "10000000-0000-0000-0000-000000000000"
}

variable "insecure_skip_verify" {
  default = true
  // set to false if server has valid certifcate; e.g. if snapcd_server_url==https://snapcd.io
}
variable "snapcd_server_url" {
  default = "http://localhost:5000"
  // The URL you use to reach the Snap CD Server from where you run `tofu apply`.
  // - snapcd-deployment-docker: "http://localhost:5000"
  // - SnapCd.Server.Host (C# project): "https://localhost:20002"
  // - SaaS subscription: "https://snapcd.io"
}


//// Passed into module

variable "snapcd_server_url_from_runner" {
  default = "http://snapcd-server:5000"
  // The URL the Runner uses to reach the Snap CD Server. This is used in the
  // State Store backend config — OpenTofu runs inside the Runner container, so
  // the URL must be reachable from there (e.g. a Docker network hostname).
  // - snapcd-deployment-docker: "http://snapcd-server:5000"
  // - SnapCd.Server.Host (C# project): "https://localhost:20002"
  // - SaaS subscription: "https://snapcd.io"
}
variable "runner_name" {
  default = "default"
}
variable "agent_name" {
  default = "default"
}
variable "stack_name" {
  default = "default"
}
variable "sample_stack_secret_name" {
  default = "sample"
}
variable "namespace_name" {
  default = "my-sample-namespace"
}

variable "runner_federated" {
  default = false
  // Set to true when the Runner authenticates with a Federated Credential, as
  // in the kind setup of github.com/schrieksoft/snapcd-deployment-kubernetes
  // (scripts/kind-up.sh). Such a Runner has no client secret to pass to the
  // State Store, so the backend password comes from TF_HTTP_PASSWORD, which the
  // Runner sets from its token.
}

variable "scoped_runner_name" {
  default = "sample-scoped-runner"
  // Name of the Runner created in section 8 of the module. It is created rather
  // than looked up, so this name must not already exist in the organization.
}

variable "scoped_namespace_name" {
  default = "sample-scoped-namespace"
  // Namespace created in section 8 of the module, to demonstrate granting a Runner
  // and role assignments into a Namespace this configuration owns. It holds no Modules.
}
