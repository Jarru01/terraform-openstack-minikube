#!/usr/bin/env bash
# Render the cloud-init templates with sample values so they can be linted
# as plain shell scripts. Usage: render-cloud-init.sh <output-dir>
set -euo pipefail

repo="$(cd "$(dirname "$0")/../.." && pwd)"
out="$(mkdir -p "$1" && cd "$1" && pwd)"
ci="$repo/cloud-init"

render() {
  # Run the console in an empty directory so no configuration is loaded.
  # The console reads one expression per line, so $1 must be a single line.
  # jsonencode + jq turn the HCL string into the exact raw text.
  (cd "$(mktemp -d)" && echo "jsonencode($1)" | terraform console) | jq -r . | jq -r . > "$2"
}

docker_vars='{ ssh_user = "ubuntu" }'
minikube_vars='{ ssh_user = "ubuntu", minikube_version = "v1.39.0", kubernetes_version = "v1.37.0", node_count = 3, cpus_per_node = 2, memory_per_node_mb = 2200 }'

cp "$ci/10-base.sh" "$out/10-base.sh"
render "templatefile(\"$ci/20-docker.sh.tftpl\", $docker_vars)" "$out/20-docker.sh"
render "templatefile(\"$ci/30-minikube.sh.tftpl\", $minikube_vars)" "$out/30-minikube.sh"

ls -l "$out"
