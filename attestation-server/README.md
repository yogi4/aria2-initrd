# TPM Attestation Server

This project implements a TPM attestation server in Go. The server validates TPM quotes and PCR (Platform Configuration Register) values provided by clients. The server uses `tpm2-tools` for TPM-related operations.

---

## Prerequisites

### On the Server Side
1. **Go**: Ensure Go 1.22 or later is installed.
2. **tpm2-tools**: The `tpm2-tools` suite must be installed for handling TPM operations.
   - Included in the provided Dockerfile.
3. **Docker**: For containerized deployments, install Docker.

### On the Client Side
1. A TPM-enabled system or a TPM emulator (e.g., `swtpm`).
2. The `tpm2-tools` suite for generating TPM quotes and PCR values.

---

## Setting Up and Running the Server

### 1. Clone the Repository
```bash
git clone https://github.com/yogi4/aria2-initrd/attestation-server.git
cd attestation-server
```

### 2. Prepare the `pcr_values.json` File
Create a `pcr_values.json` file in the project root. This file defines the expected PCR values for validation.

#### Example:
```json
{
  "0": "expected_pcr_value_0",
  "1": "expected_pcr_value_1",
  "2": "expected_pcr_value_2"
}
```
To populate this file, extract the PCR values from a trusted system state:
```bash
tpm2_pcrread sha256:0,1,2 > baseline_pcrs.txt
# Edit and format baseline_pcrs.txt into JSON format
```

### 3. Build and Run the Docker Container

#### Build the Container
```bash
docker build -t tpm-attestation-server .
```

#### Run the Container
```bash
docker run -d -p 5000:5000 --name tpm-attestation-server \
    -v $(pwd)/pcr_values.json:/app/pcr_values.json \
    tpm-attestation-server
```
- The `-v` flag mounts the `pcr_values.json` file into the container.

---

## Using the Server

### Endpoint
- **POST** `/verify`

### Request Parameters
1. **message**: TPM quote message (`quote_message.dat`).
2. **signature**: TPM quote signature (`quote_signature.dat`).
3. **nonce**: Randomly generated nonce.
4. **pubkey**: Public key used for the TPM quote (`attestation_key.pub`).
5. **pcr_values**: PCR values (`pcr_values.txt`).

### Example Client Request
```bash
curl -X POST http://<SERVER_IP>:5000/verify \
    -F "message=@/tmp/quote_message.dat" \
    -F "signature=@/tmp/quote_signature.dat" \
    -F "nonce=$(cat /tmp/nonce.txt)" \
    -F "pubkey=@/tmp/attestation_key.pub" \
    -F "pcr_values=@/tmp/pcr_values.txt"
```

### Example Response
- Success:
  ```json
  {
    "status": "OK",
    "message": "Verification successful"
  }
  ```

- Failure:
  ```json
  {
    "status": "FAIL",
    "message": "PCR 0 mismatch: expected expected_pcr_value_0, got mismatched_value"
  }
  ```

---

## Troubleshooting

### PCR Mismatch
- Ensure `pcr_values.json` is correctly configured with the baseline PCR values.
- Verify that the client is sending the correct PCR values using `tpm2_pcrread`.

### Missing Tools
- Ensure `tpm2-tools` is installed and available in the container:
  ```bash
  docker exec -it tpm-attestation-server tpm2_getrandom --version
  ```

---

## Contribution
Feel free to submit issues or pull requests to improve the server.

