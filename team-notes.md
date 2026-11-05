# Team Notes: Configuration Management with Ansible

## Team
| Member | Role | GitHub | Server | Status |
|---|---|---|---|---|
| 1 | Project Lead / Terraform Owner | M-a-web179 | local Ubuntu 22.04 (WSL2) | Deployed, destroy pending |
| 2 | | | | |
| 3 | | | | |
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
