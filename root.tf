terraform {
  required_providers {
    snapcd = {
      source  = "registry.terraform.io/schrieksoft/snapcd"
      version = "1.4.5"
    }

  }

  // Stores this deployment's own state in the Snap CD State Store instead of a
  // local terraform.tfstate file. The defaults below match the pre-configured
  // "snapcd-selfhosted-deployment-docker" setup (like the defaults in
  // variables.tf): the pre-seeded "default" State Store has the fixed ID
  // 10000000-0000-0000-0000-000000000000, username is "{organization_id}:{client_id}"
  // and password is the client secret.
  //
  // Backend blocks cannot reference variables. To point at a different server or
  // credentials, override any of these at init time, e.g.:
  //
  //   tofu init \
  //     -backend-config="address=https://localhost:20002/api/state/10000000-0000-0000-0000-000000000000/sample-deployment" \
  //     -backend-config="lock_address=https://localhost:20002/api/state/10000000-0000-0000-0000-000000000000/sample-deployment/lock" \
  //     -backend-config="unlock_address=https://localhost:20002/api/state/10000000-0000-0000-0000-000000000000/sample-deployment/unlock" \
  //     -backend-config="username=10000000-0000-0000-0000-000000000000:default" \
  //     -backend-config="password=default"
  //
  // If your server uses a self-signed certificate, also pass
  // -backend-config="skip_cert_verification=true".
  backend "http" {
    address        = "http://localhost:5000/api/state/10000000-0000-0000-0000-000000000000/sample-deployment"
    lock_address   = "http://localhost:5000/api/state/10000000-0000-0000-0000-000000000000/sample-deployment/lock"
    unlock_address = "http://localhost:5000/api/state/10000000-0000-0000-0000-000000000000/sample-deployment/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "10000000-0000-0000-0000-000000000000:default"
    password       = "default"
  }
}