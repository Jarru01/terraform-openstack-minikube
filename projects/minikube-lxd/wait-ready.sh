#!/usr/bin/env bash
# Wait until the LXD VM has finished provisioning and every minikube node is
# Ready, then print the nodes.
#
# Usage: ./wait-ready.sh [instance-name] [expected-node-count]
#
# Each check is a short `lxc exec` that is retried: while cloud-init upgrades
# packages, the LXD agent inside the VM can restart and drop a long-running
# exec session, so a single long `cloud-init status --wait` is not reliable.
set -euo pipefail

name="${1:-minikube-lxd}"
expected="${2:-3}"
deadline=$((SECONDS + ${TIMEOUT_SECONDS:-2700}))

timed_out() {
  echo "Timed out: $1" >&2
  lxc exec "$name" -- cloud-init status --long >&2 || true
  exit 1
}

as_ubuntu() { lxc exec "$name" -- runuser -l ubuntu -c "$1"; }

# 1. cloud-init. The marker line tells a real cloud-init exit code apart from
#    an `lxc exec` failure (agent not reachable), which is only retried.
echo "Waiting for cloud-init on $name ..."
while :; do
  out="$(lxc exec "$name" -- sh -c 'cloud-init status --wait >/dev/null 2>&1; echo "cloud-init-rc=$?"' 2>/dev/null || true)"
  case "$out" in
    *cloud-init-rc=0* | *cloud-init-rc=2*) break ;; # 2 = finished with warnings
    *cloud-init-rc=*)
      echo "cloud-init reported an error:" >&2
      lxc exec "$name" -- cloud-init status --long >&2 || true
      lxc exec "$name" -- tail -n 50 /var/log/cloud-init-output.log >&2 || true
      exit 1
      ;;
  esac
  [ "$SECONDS" -lt "$deadline" ] || timed_out "cloud-init did not finish"
  sleep 10
done
echo "cloud-init finished after ${SECONDS}s."

# 2. Every node Ready, and the expected number of them.
until as_ubuntu "kubectl wait --for=condition=Ready nodes --all --timeout=60s" >/dev/null 2>&1; do
  [ "$SECONDS" -lt "$deadline" ] || timed_out "nodes did not become Ready"
  sleep 10
done

ready="$(as_ubuntu "kubectl get nodes --no-headers" | awk '$2 == "Ready"' | wc -l)"
if [ "$ready" -ne "$expected" ]; then
  echo "Expected $expected Ready nodes, found $ready." >&2
  as_ubuntu "kubectl get nodes -o wide" >&2 || true
  exit 1
fi

echo "All $expected nodes Ready after ${SECONDS}s."
as_ubuntu "kubectl get nodes -o wide"
