#!/bin/sh

#Checks for TPM device: Looks for /dev/tpm0 or /dev/tpmrm0.
#Generates keys: Creates a primary key and an attestation key.
#Stores keys: Places key context files in /etc/tpm/.
#Note: This script assumes that the TPM device files are accessible and that the TPM is not locked.

echo "Running TPM initialization script..."

# Check for TPM device
if [ -e /dev/tpm0 ] || [ -e /dev/tpmrm0 ]; then
    echo "TPM detected. Setting up TPM keys..."

    mkdir -p /etc/tpm

    # Create a primary key
    tpm2_createprimary -C o -g sha256 -G rsa -c /etc/tpm/primary.ctx
    if [ $? -ne 0 ]; then
        echo "Failed to create primary key."
        exit 1
    fi

    # Create an attestation key
    tpm2_create -C /etc/tpm/primary.ctx -g sha256 -G rsa \
        -u /etc/tpm/attestation_key.pub -r /etc/tpm/attestation_key.priv
    if [ $? -ne 0 ]; then
        echo "Failed to create attestation key."
        exit 1
    fi

    # Load the attestation key
    tpm2_load -C /etc/tpm/primary.ctx \
        -u /etc/tpm/attestation_key.pub -r /etc/tpm/attestation_key.priv \
        -c /etc/tpm/attestation_key.ctx
    if [ $? -ne 0 ]; then
        echo "Failed to load attestation key."
        exit 1
    fi

    echo "TPM setup complete."
else
    echo "No TPM device found. Skipping TPM setup."
    exit 1
fi
