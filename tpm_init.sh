#!/bin/sh
# TPM Initialization and Attestation Script
# Parses parameters, checks for TPM device, sets up keys, and performs attestation.

set -e

# Parse kernel command-line arguments into variables
parse_cmdline() {
    for param in $(cat /proc/cmdline); do
        case "$param" in
            tpm_attestation=*)
                TPM_ATTESTATION="${param#*=}" ;;
            attestation_server=*)
                ATTESTATION_SERVER="${param#*=}" ;;
        esac
    done
}

# Main Execution
parse_cmdline

if [ "$TPM_ATTESTATION" != "1" ]; then
    echo "TPM attestation is not enabled. Skipping attestation."
    exit 0
fi

if [ -z "$ATTESTATION_SERVER" ]; then
    echo "No attestation server provided. Halting."
    exit 1
fi

echo "TPM attestation is enabled. Using server: $ATTESTATION_SERVER"

# TPM Initialization and Attestation Logic
tpm2_createprimary -C o -g sha256 -G rsa -c /etc/tpm/primary.ctx
tpm2_create -C /etc/tpm/primary.ctx -g sha256 -G rsa \
    -u /etc/tpm/attestation_key.pub -r /etc/tpm/attestation_key.priv
tpm2_load -C /etc/tpm/primary.ctx \
    -u /etc/tpm/attestation_key.pub -r /etc/tpm/attestation_key.priv \
    -c /etc/tpm/attestation_key.ctx

# Read PCR values
tpm2_pcrread sha256:0,1,2 > /tmp/pcr_values.txt

# Generate a nonce
NONCE=$(head -c 20 /dev/urandom | base64)
echo "$NONCE" > /tmp/nonce.txt

# Create a quote
tpm2_quote \
    --key-context /etc/tpm/attestation_key.ctx \
    --pcr-list sha256:0,1,2 \
    --message /tmp/quote_message.dat \
    --signature /tmp/quote_signature.dat \
    --qualification /tmp/nonce.txt

# Send attestation data to the server
RESPONSE=$(curl -s -X POST \
    -F "message=@/tmp/quote_message.dat" \
    -F "signature=@/tmp/quote_signature.dat" \
    -F "nonce=$NONCE" \
    -F "pubkey=@/etc/tpm/attestation_key.pub" \
    -F "pcr_values=@/tmp/pcr_values.txt" \
    "$ATTESTATION_SERVER")

if [ "$RESPONSE" = "OK" ]; then
    echo "TPM attestation successful."
else
    echo "TPM attestation failed. Halting system."
    exit 1
fi
