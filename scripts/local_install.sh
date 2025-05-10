#!/bin/sh
# This script installs Ollama from local built on Linux.

set -eu

available() { command -v $1 >/dev/null; }

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    # Running as root, no need for sudo
    if ! available sudo; then
        error "This script requires superuser permissions. Please re-run as root."
    fi

    SUDO="sudo"
fi


$SUDO systemctl stop ollama.service
$SUDO cp -f dist/bin/ollama /usr/local/bin/
$SUDO cp -rf dist/lib/ollama /usr/local/lib/

$SUDO systemctl daemon-reload && $SUDO systemctl restart ollama.service
