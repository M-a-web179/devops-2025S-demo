# Team Notes: Configuration Management with Ansible

## Team
| Member | Role | GitHub | Server | Status |
|---|---|---|---|---|
| 1 | Project Lead / Terraform Owner | M-a-web179 | local Ubuntu 22.04 (WSL2) | Deployed, destroy pending |
| 2 | Member | HelloWorldVictor | Ubuntu 22.04 container (Docker on macOS) | Deployed + destroyed |
| 3 | Member | Dominion Yusuf | | |
| 4 | Member | Victor-VIO | | |

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

## Member 2 evidence (HelloWorldVictor)
Server: Ubuntu 22.04 container on macOS (Docker via Colima), built from
`server/Dockerfile`. It runs systemd + sshd, key-only login, passwordless
sudo for the Ansible user. SSH on 127.0.0.1:2222, app on 127.0.0.1:8000.
The repo is mounted at the same path inside the container because the
playbook builds the image on the target from `{{ playbook_dir }}/..`.
Everything is driven by `scripts/member-lab.sh` (`up`, then `destroy`).

- SSH key: own ed25519 key `~/.ssh/devops-ansible-member2` (private key never committed)
- terraform.tfvars: local only, gitignored, deleted on destroy
- Terraform: evidence/member2/terraform-{init,validate,plan,apply}.log
- Ping: evidence/member2/ping.txt
- Run 1: evidence/member2/run1.log (changed=4)
- Run 2: evidence/member2/run2.log (changed=0)
- Health: evidence/member2/health.txt (HTTP 200)

Why it is idempotent on this host: run 1 installs docker.io and
python3-docker, builds the image and starts the container. On run 2 apt
sees the packages are present, the Docker service is already started and
enabled, the image already exists (docker_image with source: build only
builds when the image is missing), and docker_container finds a running
container whose config already matches. Nothing differs from the desired
state, so every task reports ok and the recap shows changed=0.

## Member 2 destroy evidence
- terraform destroy: evidence/member2/destroy-terraform.log (Destroy complete! Resources: 1 destroyed)
- Container, image and Docker volumes removed: evidence/member2/destroy-container.log (docker ps -a empty, /health refused)

## Destroy evidence
(to be filled in at the end)

## Member 1 destroy evidence
- terraform destroy: evidence/member1/destroy-terraform.log (Destroy complete! Resources: 1 destroyed)
- Container and image removed: evidence/member1/destroy-container.log (docker ps -a empty, /health refused)
