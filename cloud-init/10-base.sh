#!/bin/bash
# Bring the image up to date before installing anything else.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y -o Dpkg::Options::=--force-confold upgrade
apt-get install -y ca-certificates curl
