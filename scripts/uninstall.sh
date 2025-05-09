#!/bin/sh
# This script uninstalls Ollama on Linux.

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
$SUDO rm -f /usr/local/bin/ollama 
$SUDO rm -rf /usr/local/lib/ollama/


