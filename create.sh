#!/bin/bash

set -eu

JHUB_VARIANT="${1}"
JHUB_DOMAIN="${2}"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
JHUB_VARIANT_DIR="${SCRIPT_DIR}/variants/${JHUB_VARIANT}"
DEST_RUN_DIR="/opt/jupyterhub"

MAMBAFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh"
TRAEFIK_URL="https://github.com/traefik/traefik/releases/download/v2.10.4/traefik_v2.10.4_linux_amd64.tar.gz"

if [ $(id -u) -ne 0 ]
then
    echo "script must be run as root"
    exit 1
fi

if [[ ! -d "${JHUB_VARIANT_DIR}" ]]
then
    echo "Variant ${JHUB_VARIANT} does not exist?"
    exit 1
fi

# 0. Copy over to the final run directory
cp -a "${JHUB_VARIANT_DIR}" "${DEST_RUN_DIR}"
 
# 1. Download/install mambaforge
if [[ ! -d /opt/mambaforge ]]
then
    wget -O /tmp/mambaforge_install.sh "${MAMBAFORGE_URL}"
    
    # -b : batch mode
    # -p : prefix
    chmod u+x /tmp/mambaforge_install.sh
    /tmp/mambaforge_install.sh -b -p /opt/mambaforge
    rm /tmp/mambaforge_install.sh
fi

# 2. Create the jupyterhub env
source /opt/mambaforge/etc/profile.d/conda.sh
source /opt/mambaforge/etc/profile.d/mamba.sh
mamba env create -f "${DEST_RUN_DIR}/jupyterhub_env.yaml"

# 3. Download & install traefik
cp -a "${SCRIPT_DIR}/traefik" "${DEST_RUN_DIR}/traefik"
wget -O /tmp/traefik.tar.gz https://github.com/traefik/traefik/releases/download/v2.10.4/traefik_v2.10.4_linux_amd64.tar.gz
tar -xv -C "${DEST_RUN_DIR}/traefik" -f /tmp/traefik.tar.gz traefik
rm /tmp/traefik.tar.gz
sed -i "s/###JHUB_DOMAIN###/${JHUB_DOMAIN}/g" "${DEST_RUN_DIR}/traefik/jhub_config.yaml"

# 4. Prepare the run directory
cp "${SCRIPT_DIR}/run.sh" "${DEST_RUN_DIR}/run.sh"
chmod u+x "${DEST_RUN_DIR}/run.sh" 

echo
echo "##############################################################################"
echo "Created ${DEST_RUN_DIR}. Use the run.sh script there to start the jupyterhub"
echo "##############################################################################"
echo
