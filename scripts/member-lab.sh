#!/usr/bin/env bash
# Runs the full member lab against a local Ubuntu container and saves evidence.
#
#   MEMBER=2 ./scripts/member-lab.sh up       # server + terraform + ping + 2 runs + health
#   MEMBER=2 ./scripts/member-lab.sh destroy  # terraform destroy + remove container/image
#
# Needs: docker, terraform, ansible (with community.docker), curl.
set -euo pipefail

: "${MEMBER:?set MEMBER to your member number, e.g. MEMBER=2}"
SSH_USER="${SSH_USER:-$(whoami)}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/devops-ansible-member${MEMBER}}"
SSH_PORT="${SSH_PORT:-2222}"
APP_PORT=8000

REPO="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE="$REPO/evidence/member${MEMBER}"
SERVER_IMAGE="ubuntu-ssh-server"
SERVER_NAME="ubuntu-server-member${MEMBER}"
DOCKER_VOLUME="${SERVER_NAME}-docker"
CONTAINERD_VOLUME="${SERVER_NAME}-containerd"

# The inventory from Terraform has no port, so tell Ansible here.
export ANSIBLE_REMOTE_PORT="$SSH_PORT"
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_FORCE_COLOR=0
export TF_IN_AUTOMATION=1

mkdir -p "$EVIDENCE"
cd "$REPO"

up() {
  # 1. Own SSH key (private key stays in ~/.ssh, never in the repo)
  if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -N "" -C "member${MEMBER}-devops-ansible" -f "$SSH_KEY"
  fi

  # 2. Ubuntu server: systemd + sshd, privileged so Docker can run inside it.
  #    Repo is mounted at the same path because the playbook builds from it on the host.
  docker build -t "$SERVER_IMAGE" \
    --build-arg SSH_USER="$SSH_USER" \
    --build-arg SSH_PUBKEY="$(cat "$SSH_KEY.pub")" \
    server/
  # Start from a clean server every time
  docker rm -f "$SERVER_NAME" >/dev/null 2>&1 || true
  docker volume rm "$DOCKER_VOLUME" "$CONTAINERD_VOLUME" >/dev/null 2>&1 || true
  docker run -d --name "$SERVER_NAME" --hostname "member${MEMBER}-server" \
    --privileged --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw --tmpfs /run --tmpfs /run/lock \
    -v "$DOCKER_VOLUME":/var/lib/docker \
    -v "$CONTAINERD_VOLUME":/var/lib/containerd \
    -v "$REPO":"$REPO":ro \
    -p "$SSH_PORT":22 -p "$APP_PORT":"$APP_PORT" \
    "$SERVER_IMAGE"

  echo "Waiting for SSH..."
  for _ in $(seq 1 30); do
    ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 \
      "$SSH_USER@127.0.0.1" true 2>/dev/null && break
    sleep 2
  done

  # 3. Terraform -> ansible/inventory.ini (tfvars is gitignored)
  cat > terraform/terraform.tfvars <<TFVARS
server_host  = "127.0.0.1"
ssh_user     = "${SSH_USER}"
ssh_key_path = "${SSH_KEY}"
TFVARS
  terraform -chdir=terraform init -no-color      | tee "$EVIDENCE/terraform-init.log"
  terraform -chdir=terraform validate -no-color  | tee "$EVIDENCE/terraform-validate.log"
  terraform -chdir=terraform plan -no-color      | tee "$EVIDENCE/terraform-plan.log"
  terraform -chdir=terraform apply -auto-approve -no-color | tee "$EVIDENCE/terraform-apply.log"

  # 4. Ping
  ansible -i ansible/inventory.ini app -m ping | tee "$EVIDENCE/ping.txt"

  # 5. Playbook twice; second run must be changed=0
  ansible-playbook -i ansible/inventory.ini ansible/playbook.yml | tee "$EVIDENCE/run1.log"
  ansible-playbook -i ansible/inventory.ini ansible/playbook.yml | tee "$EVIDENCE/run2.log"
  if grep -Eq 'changed=0 ' "$EVIDENCE/run2.log"; then
    echo "OK: second run is idempotent (changed=0)"
  else
    echo "FAIL: second run changed something" >&2; exit 1
  fi

  # 6. Health
  curl -si "http://127.0.0.1:${APP_PORT}/health/" | tee "$EVIDENCE/health.txt"
  echo
  grep -q '200 OK' "$EVIDENCE/health.txt" && echo "OK: /health/ returned 200"
}

destroy() {
  terraform -chdir=terraform destroy -auto-approve -no-color | tee "$EVIDENCE/destroy-terraform.log"

  {
    echo "\$ docker rm -f $SERVER_NAME"; docker rm -f "$SERVER_NAME"
    echo "\$ docker rmi $SERVER_IMAGE";  docker rmi "$SERVER_IMAGE"
    echo "\$ docker volume rm $DOCKER_VOLUME $CONTAINERD_VOLUME"
    docker volume rm "$DOCKER_VOLUME" "$CONTAINERD_VOLUME"
    echo "\$ docker ps -a --filter name=$SERVER_NAME"; docker ps -a --filter "name=$SERVER_NAME"
    echo "\$ docker images $SERVER_IMAGE"; docker images "$SERVER_IMAGE"
    echo "\$ curl -sS http://127.0.0.1:${APP_PORT}/health/"
    curl -sS "http://127.0.0.1:${APP_PORT}/health/" 2>&1 || true
  } | tee "$EVIDENCE/destroy-container.log"

  # terraform destroy deletes the shared inventory.ini; put Member 1's version back
  git checkout -- ansible/inventory.ini
  rm -f terraform/terraform.tfvars
}

case "${1:-}" in
  up) up ;;
  destroy) destroy ;;
  *) echo "usage: MEMBER=N $0 up|destroy" >&2; exit 1 ;;
esac
