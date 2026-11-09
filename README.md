# devops-2025S-demo
class demo for devops class
pretending to add more details to the readme
completed.

## Infrastructure and configuration

Terraform currently generates an inventory for an existing Ubuntu server.
The role-based deployment installs Docker, hardens SSH, configures host and
Docker forwarding firewalls, and pulls and health-checks the application image.
See [Ansible setup](ansible/README.md) and [architecture](docs/architecture.md).
Each operator supplies an ignored terraform.tfvars and ansible/local.yml.
