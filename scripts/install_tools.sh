#!/usr/bin/env bash
set -euo pipefail

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Installing kubectl..."
  curl -sSL -o kubectl https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "Installing helm..."
  curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
