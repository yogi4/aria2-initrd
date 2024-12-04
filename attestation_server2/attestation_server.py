from flask import Flask, request
import tempfile
import subprocess
import os

app = Flask(__name__)

@app.route('/verify', methods=['POST'])
def verify():
    # Check if all required files are present
    if 'message' not in request.files or 'signature' not in request.files or 'nonce' not in request.form or 'pubkey' not in request.files:
        return 'Missing required data', 400

    message_file = request.files['message']
    signature_file = request.files['signature']
    pubkey_file = request.files['pubkey']
    nonce = request.form['nonce']

    # Create temporary directory
    with tempfile.TemporaryDirectory() as tmpdirname:
        # Save files to temporary directory
        message_path = os.path.join(tmpdirname, 'quote_message.dat')
        signature_path = os.path.join(tmpdirname, 'quote_signature.dat')
        pubkey_path = os.path.join(tmpdirname, 'attestation_key.pub')
        nonce_path = os.path.join(tmpdirname, 'nonce.txt')
        pcrs_path = os.path.join(tmpdirname, 'pcrs.txt')

        message_file.save(message_path)
        signature_file.save(signature_path)
        pubkey_file.save(pubkey_path)

        with open(nonce_path, 'w') as f:
            f.write(nonce)

        # Run tpm2_checkquote
        cmd = [
            'tpm2_checkquote',
            '--public', pubkey_path,
            '--message', message_path,
            '--signature', signature_path,
            '--qualification', nonce_path,
            '--pcrs', pcrs_path
        ]

        try:
            result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as e:
            print("tpm2_checkquote failed")
            print(e.stderr.decode())
            return 'FAIL', 400

        # Read PCR values from pcrs_path
        with open(pcrs_path, 'r') as f:
            pcr_values = f.read()
            # For testing, we can print the PCR values
            print("PCR Values:")
            print(pcr_values)

            # Here, you can implement logic to decide whether the PCR values are acceptable.
            # For testing, we can accept any PCR values.

        return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5020)
