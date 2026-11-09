# Ansible deployment

The playbook configures an existing Ubuntu host with systemd and SSH key access.
It installs Docker, restricts host and Docker-forwarded traffic, hardens SSH, and
pulls and runs an application image. The current team repository is Campus
Notifier. Image, ports, health path, environment and volumes are configurable.

## Prerequisites

- Git, Terraform >= 1.5, Ansible and Docker on the controller for the local lab.
- An Ubuntu systemd host, a non-root sudo user, and that user's public SSH key
  installed in authorized_keys. The private key stays on the controller.
- A registry image that supports the server architecture and contains Python for
  the container health check. The default is the published class demo, pinned by
  digest. For a team GHCR image, replace app_image with its published digest.
- The Docker iptables firewall backend. The forwarding policy deliberately
  controls this dedicated application's server, including existing containers.
- Set ssh_allowed_cidr to the operator's /32 or approved VPN CIDR before cloud use.

## Setup and inventory

From the repository root:

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install ansible ansible-lint==26.11.0
ansible-galaxy collection install -r ansible/requirements.yml
ssh-keygen -t ed25519 -f ~/.ssh/sokosmart-f3-member3
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit the ignored tfvars with your host, sudo user and private-key path.
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

The current Terraform manages only ansible/inventory.ini. It expects the server
to exist already. The inventory is now ignored instead of tracking Member 1's
machine details. ansible/inventory.ini.example provides the static format.
If Part 1 changes the inventory output, preserve the app group or update hosts
in site.yml. No AWS instances are created by this version of Terraform.

Create an ignored ansible/local.yml for machine-specific settings and secrets.
Never put secrets in group_vars/all.yml or commit local.yml. For example:

```yaml
ansible_port: 22
ssh_allowed_cidr: "YOUR_PUBLIC_IP/32"
app_env:
  DJANGO_SECRET_KEY: "GENERATE_YOUR_OWN_VALUE"
```

For a local lab, ansible_port is the host's forwarded SSH port (2224 in Member 3's
test), while ssh_port remains the server's internal port 22. Docker-forwarded
SSH reaches the server from the Docker bridge gateway, so use that gateway /32
for ssh_allowed_cidr. Bind the outer lab ports to 127.0.0.1.

Generate secrets locally with Python secrets or Ansible Vault. Pass environment
variables to the container at runtime. The container task uses no_log.
Campus Notifier's default SQLite data lives in its container. For durable data,
provide PostgreSQL settings in app_env or an application-supported volume path
in app_volumes. A volume alone does not change the app's database configuration.

## Run and verify

```sh
export ANSIBLE_CONFIG="$PWD/ansible/ansible.cfg"
ansible -i ansible/inventory.ini app -m ping -e @ansible/local.yml
ansible-playbook -i ansible/inventory.ini ansible/site.yml -e @ansible/local.yml
ansible-playbook -i ansible/inventory.ini ansible/site.yml -e @ansible/local.yml
curl -i http://YOUR_SERVER:8000/health/
ansible-lint ansible/site.yml ansible/playbook.yml ansible/roles
```

The old ansible/playbook.yml imports site.yml to preserve the existing entry
point. The second run must show changed=0, failed=0 and unreachable=0. Install
dependencies first; ansible-lint must be able to resolve the two collections.

## Roles and idempotency

- docker uses apt state=present and systemd desired state. Nested Docker alone
  gets the vfs configuration. Its restart handler runs only on config changes.
- ssh_hardening checks authorized_keys before writing a complete sshd_config.
  The template is validated with sshd -t before replacement. Password, keyboard
  interactive, empty-password and root logins are disabled. Restart is a handler.
- firewall opens the restricted SSH rule before enabling UFW with default-deny
  ingress. It allows the app port and outgoing connections. Docker published
  ports bypass UFW INPUT, so a persistent DOCKER-USER policy also blocks external
  forwarding to other ports. IPv6 is filtered when Docker creates its IPv6 chain.
  Dedicated-server assumption: unrelated forwarded workloads will be blocked.
- app pulls a digest-pinned image only if missing, reconciles the container's
  configuration, and waits for HTTP 200. There is no unconditional docker run.
  The uri and debug tasks are read-only. An unchanged image/configuration leaves
  the second run unchanged. To deploy a release, change the image digest.

## Disposable local server

ansible/tests/Dockerfile is the Ubuntu fixture from Member 2's PR. Build it with
SSH_USER=devops and SSH_PUBKEY set to your public key. Run it with systemd,
--privileged, --cgroupns=host, /sys/fs/cgroup mounted, and /run and /run/lock as
tmpfs. This fixture requires a trusted local Docker host. It is a lab substitute
for Ubuntu, and its privileged mode is unnecessary on a normal cloud VM.

## Cleanup and evidence

Remove the application container and its image on the target before deleting the
host, then run terraform -chdir=terraform destroy. On the local track also remove
your outer server container and its fixture image. Verify terraform state list
is empty and the server/app are absent. Avoid deleting other members' resources.
The shared image digest may be used by other containers; remove only your own
test artifacts.

Store evidence under evidence/memberN. Stage each path explicitly. Use git add -f
for named .log files. Never stage private keys, tfvars, state, local.yml or .env.
CI runs ansible-lint. Member 3's runtime, firewall, SSH and cleanup evidence lives
under evidence/member3.
