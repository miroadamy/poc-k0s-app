#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/copy-k8s.sh <user>@<host> [/remote/path]
# Example:
#   ./scripts/copy-k8s.sh root@1.2.3.4 /root/poc-k0s-app

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <user>@<host> [/remote/path]" >&2
  exit 1
fi

REMOTE="$1"
REMOTE_PATH="${2:-~/poc-k0s-app}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Copying demo-app/k8s to ${REMOTE}:${REMOTE_PATH}/demo-app/k8s"
ssh "${REMOTE}" "mkdir -p '${REMOTE_PATH}/demo-app'"
rsync -av --delete "${REPO_ROOT}/demo-app/k8s/" "${REMOTE}:${REMOTE_PATH}/demo-app/k8s/"

echo "Done. On the server you can run:"
cat <<EOF
  cd ${REMOTE_PATH}
  kubectl apply -k demo-app/k8s
EOF
