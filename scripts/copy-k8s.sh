#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/copy-k8s.sh [-i /path/to/key] <user>@<host> [/remote/path]
# Example:
#   ./scripts/copy-k8s.sh -i ~/.ssh/id_rsa root@1.2.3.4 /root/poc-k0s-app

IDENTITY=""
while getopts ":i:" opt; do
  case "$opt" in
    i) IDENTITY="$OPTARG" ;;
    *)
      echo "Usage: $0 [-i /path/to/key] <user>@<host> [/remote/path]" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 [-i /path/to/key] <user>@<host> [/remote/path]" >&2
  exit 1
fi

REMOTE="$1"
REMOTE_PATH="${2:-~/poc-k0s-app}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SSH_OPTS=()
RSYNC_OPTS=()
if [[ -n "$IDENTITY" ]]; then
  SSH_OPTS=(-i "$IDENTITY")
  RSYNC_OPTS=(-e "ssh -i ${IDENTITY}")
fi

echo "Copying demo-app/k8s to ${REMOTE}:${REMOTE_PATH}/demo-app/k8s"
ssh "${SSH_OPTS[@]}" "${REMOTE}" "mkdir -p '${REMOTE_PATH}/demo-app'"
rsync -av --delete "${RSYNC_OPTS[@]}" "${REPO_ROOT}/demo-app/k8s/" "${REMOTE}:${REMOTE_PATH}/demo-app/k8s/"

echo "Done. On the server you can run:"
cat <<EOF
  cd ${REMOTE_PATH}
  kubectl apply -k demo-app/k8s
EOF
