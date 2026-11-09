# Deployment architecture

The current application is Campus Notifier, a Django application in one Docker
container. Ansible's app_image, app_container_port and app_health_path can be
changed for a separately published SokoSmart image.

Terraform currently generates the controller's Ansible inventory for an existing
Ubuntu server. Ansible connects by SSH as a non-root sudo user, installs Docker,
configures the firewall and SSH daemon, and deploys the registry image.

The server exposes restricted key-only SSH and the application port. UFW protects
host ingress. A DOCKER-USER forwarding policy covers Docker's published ports,
which otherwise bypass UFW's host-input rules. Runtime secrets are supplied from
an ignored controller variables file or Ansible Vault and hidden in task output.

The default classroom image uses SQLite inside its container. Production data
requires an external database or a deliberately configured persistent path.
Cloud VM/network provisioning and registry publishing are separate team tasks.
