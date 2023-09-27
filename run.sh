#!/bin/bash

set -eu

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ $(id -u) -ne 0 ]
then
	echo "script must be run as root"
    exit 1
fi

source /opt/mambaforge/etc/profile.d/conda.sh
source /opt/mambaforge/etc/profile.d/mamba.sh
mamba activate jupyterhub

cd ${SCRIPT_DIR}
docker compose up -d
jupyterhub -f jupyterhub_config.py
