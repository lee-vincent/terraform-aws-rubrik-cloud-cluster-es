#! /bin/bash

KEYNAME="rubrik-cloud-cluster"
KEYFILE="${HOME}/.ssh/${KEYNAME}"

if [ ! -f "${KEYFILE}" ]; then
    ssh-keygen -b 2048 -C "" -f "${KEYFILE}" -N "" -q
fi

# when terraform plan or terraform apply is run, these sourced
# environment variables will set corresponding terraform input
# variables
# var.rubrik_public_key=TF_VAR_rubrik_public_key
# var.rubrik_private_key=TF_VAR_rubrik_private_key
# var.rubrik_key_name=TF_VAR_rubrik_key_name
export TF_VAR_rubrik_public_key="$(ssh-keygen -y -f ${KEYFILE})"
export TF_VAR_rubrik_private_key="$(cat ${KEYFILE})"
export TF_VAR_rubrik_key_name="${KEYNAME}"