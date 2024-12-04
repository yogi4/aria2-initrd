from flask import Flask, request, jsonify
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
import base64
import json
import os

app = Flask(__name__)

# Load expected PCR values
with open('pcr_values.json', 'r') as f:
    expected_pcr_values = json.load(f)

# Load attestation public key
with open('public_keys/attestation_key.pub', 'rb') as f:
    public_key_data = f.read()
    public_key = serialization.load_pem_public_key(public_key_data)

@app.route('/verify', methods=['POST'])
def verify():
    try:
        # Get the uploaded files and nonce
        message_file = request.files['message']
        signature_file = request.files['signature']
        nonce = request.form['nonce']

        # Read the data
        message = message_file.read()
        signature = signature_file.read()

        # Verify the signature
        public_key.verify(
            signature,
            message,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )

        # Parse the message
        # The message is in TPM2B_ATTEST structure; we need to parse it.
        # For simplicity, we'll assume it's in a format we can process.
        # In a real-world scenario, use a library to parse the TPM2 structures.

        # For example, if the message is in CBOR or JSON format:
        message_data = json.loads(message.decode('utf-8'))

        # Verify the nonce
        if message_data['extraData'] != nonce.encode():
            return 'Nonce mismatch', 400

        # Verify PCR values
        for pcr_index, expected_value in expected_pcr_values.items():
            if message_data['pcrDigest'][pcr_index] != expected_value:
                return 'PCR value mismatch', 400

        # If all checks pass
        return 'OK', 200

    except Exception as e:
        print(f"Verification failed: {e}")
        return 'Verification failed', 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=443, ssl_context=('cert.pem', 'key.pem'))
