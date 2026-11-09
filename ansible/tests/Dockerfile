# Local Ubuntu 22.04 "server" for the Ansible lab.
# Runs systemd + sshd so Ansible can manage it like a real host.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive container=docker

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      systemd systemd-sysv openssh-server sudo python3 curl ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && systemctl enable ssh \
 && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config \
 && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config

# Login user with key-only SSH and passwordless sudo (playbook uses become).
# Only the PUBLIC key is passed in; the private key never leaves the laptop.
ARG SSH_USER
ARG SSH_PUBKEY
RUN useradd -m -s /bin/bash "$SSH_USER" \
 && echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$SSH_USER" \
 && chmod 440 "/etc/sudoers.d/$SSH_USER" \
 && install -d -m 700 -o "$SSH_USER" -g "$SSH_USER" "/home/$SSH_USER/.ssh" \
 && echo "$SSH_PUBKEY" > "/home/$SSH_USER/.ssh/authorized_keys" \
 && chown "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh/authorized_keys" \
 && chmod 600 "/home/$SSH_USER/.ssh/authorized_keys"

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
