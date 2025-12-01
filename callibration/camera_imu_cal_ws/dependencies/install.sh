#!/usr/bin/env bash
set -Eeuo pipefail

# Install packages from apt.txt
apt update
apt install -y --no-install-recommends 
(cat ./apt.txt) | xargs -r apt-get install -y --no-install-recommends

# Install packages from requirements.txt and requirements.$VERSION_ID.txt
pip3 install --no-cache-dir -r ./requirements.txt