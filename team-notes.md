# Team Notes: Configuration Management with Ansible

## Team
| Member | Role | GitHub | Server | Status |
|---|---|---|---|---|
| 1 | Project Lead / Terraform Owner | M-a-web179 | local Ubuntu 22.04 (WSL2) | Deployed, destroy pending |
| 2 | | | | |
| 3 | Ansible owner | domyusuf | Ubuntu 22.04 container on macOS | Deployed and destroyed |
| 4 | | | | |

## Checklist
- [ ] All 4 members added to the repo
- [ ] Terraform merged via reviewed PR
- [ ] Ansible merged via reviewed PR
- [ ] Every member: ping succeeds
- [ ] Every member: playbook run twice, second run changed=0
- [ ] Every member: /health returns 200
- [ ] Every member: server destroyed + evidence
- [ ] No secrets in Git (checked)
- [ ] Repo URL submitted on Canvas

## Security rules
No cloud credentials, passwords, or private SSH keys in Git or chat.
Each member uses their own keys and their own host.

## Environment note
No cloud account was used because of payment-method constraints.
Terraform (local provider) generates ansible/inventory.ini for a local
Ubuntu host reachable over SSH. Instructor approval: (paste reply here).

## Member 1 evidence
- Ping: evidence/member1/ping.txt
- Run 1: evidence/member1/run1.log (changed=3)
- Run 2: evidence/member1/run2.log (changed=0)
- Health: evidence/member1/health.txt (HTTP 200)

## Why the playbook is idempotent
Each task declares a desired state, not an action. apt (state: present)
installs only if the package is missing. service (state: started,
enabled: true) changes nothing if Docker is already running and enabled.
docker_image and docker_container compare desired vs actual state and
only act on a difference. A shell: docker run would run every time and
report changed or fail on a name conflict. The uri and debug tasks are
read-only, so they report ok.

## Members 2-4 evidence
(each member adds their own section here)

## Destroy evidence
(to be filled in at the end)

## Member 1 destroy evidence
- terraform destroy: evidence/member1/destroy-terraform.log (Destroy complete! Resources: 1 destroyed)
- Container and image removed: evidence/member1/destroy-container.log (docker ps -a empty, /health refused)

## Member 3 — Ansible Part 2

Implemented four roles: docker, app, firewall and ssh_hardening. The legacy
playbook.yml imports site.yml. Docker installation uses desired package/service
states. The app role pulls a digest-pinned registry image, reconciles the
container and environment, defines a health check, and waits for HTTP 200.
Runtime secrets are in ignored ansible/local.yml and hidden by no_log.

Validation on a fresh, disposable Ubuntu 22.04 systemd server:
- Terraform init, validate, plan and apply generated inventory (logs below).
- ansible -m ping returned pong.
- Run 1: ok=25 changed=16 unreachable=0 failed=0.
- Run 2: ok=22 changed=0 unreachable=0 failed=0.
- /health/ returned HTTP 200 with {"status": "ok"}; Docker reported healthy.
- sshd -t passed; effective config disables root/password/keyboard-interactive
  login and permits public-key authentication for the deployment user.
- UFW allows SSH only from the local Docker gateway /32 and permits app port
  8000. A separate Docker client reached port 8000 but was blocked from an
  intentionally published test port 9000 by the DOCKER-USER policy.
- ansible-lint passed with zero failures and zero warnings in its rule summary.
- Terraform destroy removed the inventory resource and state list was empty.
  The app container/image and outer Ubuntu container/fixture image were removed.
  The app endpoint then refused connections.

Idempotency follows from apt state=present, service state=started/enabled,
templates that change only when contents differ, handlers that restart only on
changes, docker_image that pulls only if missing, and docker_container that
compares the declared image/configuration to the running container. Health
queries and fact gathering are read-only. The firewall script runs from a
persistent oneshot service and on configuration-change handlers, rather than
unconditionally on each playbook run.

Evidence under evidence/member3:
terraform-init.log, terraform-validate.log, terraform-plan.log,
terraform-apply.log, ping.txt, run1.log, run2.log, health.txt, homepage.png,
security.txt, firewall-test.txt, ansible-lint.txt, destroy-app.log,
destroy-terraform.log, state-after-destroy.txt, destroy-server.log,
secret-scan.txt, pr.png, commit.png and review.png.

Integration scope:
- This team repo contains Campus Notifier. The test deploys its published demo
  image. SokoSmart can use the same roles with its own image, port 5000 and
  /health path. The team must publish that image before selecting it.
- Existing Terraform manages inventory only; the Ubuntu lab fixture is started
  separately. Cloud VM/network provisioning belongs to Part 1 and was not run.
- No main ruleset or security-scan policy was changed by this Part 2 PR.
- Issues are disabled on the team repo, so a separate assigned task issue could
  not be opened. An owner can enable issues and link the Part 2 PR afterward.
- Optional cloud dynamic inventory, fail2ban and unattended-upgrade mastery
  extensions are not included in this local, static-inventory implementation.

Reviews completed:
- Member 1 PR #1: https://github.com/M-a-web179/devops-2025S-demo/pull/1#pullrequestreview-5828006111
- Member 2 PR #2: https://github.com/M-a-web179/devops-2025S-demo/pull/2#pullrequestreview-5828006548
