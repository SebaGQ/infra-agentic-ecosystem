#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

if ! systemctl list-unit-files | grep -q 'amazon-ssm-agent'; then
  if command -v snap >/dev/null 2>&1; then
    snap install amazon-ssm-agent --classic || true
  fi
fi

if ! command -v curl >/dev/null 2>&1; then
  sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
    -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' \
    /etc/apt/sources.list || true
  find /etc/apt/sources.list.d -type f -name '*.list' -exec sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
    -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' {} \; || true
  apt-get update
  apt-get install -y curl ca-certificates
fi

systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl enable --now amazon-ssm-agent.service || true

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

chmod 600 /etc/rancher/k3s/k3s.yaml

cat >/etc/profile.d/k3s.sh <<'EOF'
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
EOF

systemctl enable --now k3s
