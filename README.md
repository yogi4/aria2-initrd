# aria2-initrd

A minimal initrd implementation using `aria2` for downloading files during the early boot process. This project is designed for environments where fetching large files (e.g., container images or boot configurations) from remote sources is essential.

## Features

- **Containerized Build Process:** Uses a Docker container to ensure a consistent and reproducible build environment.
- **Efficient File Downloads:** Utilizes [aria2](https://github.com/aria2/aria2), a lightweight and high-performance download utility supporting HTTP(S), FTP, and BitTorrent protocols.
- **Lightweight Design:** Aimed at minimal environments, keeping the initrd as small as possible.
- **Highly Configurable:** Supports passing custom download URLs and options through kernel parameters.
- **Parallelism:** Leverages aria2's ability to perform concurrent downloads for faster bootstrapping.
- **TPM Attestation Support:** Verifies the integrity of the boot process using TPM-based attestation.

## Use Cases

- **HPC Cluster Bootstrapping:** Fetching configuration files or images for stateless node setups.
- **Diskless Systems:** Loading operating system components or tools directly into memory.
- **Custom Deployment Workflows:** Downloading initialization resources for custom boot environments.
- **Secure Boot Environments:** Ensuring integrity with TPM attestation.

## Getting Started

### Prerequisites

- Docker installed on your system.

### Using the Pre-Built Container to Build the Initrd

A pre-built container image is available on GitHub Container Registry (GHCR) to simplify the initrd building process.

1. Pull the pre-built container:
   ```bash
   docker pull ghcr.io/openchami/aria2-initrd:latest
   ```

2. Run the container to build the initrd:
   ```bash
   docker run --rm -v "$(pwd)/output:/workspace/output" ghcr.io/openchami/aria2-initrd:latest
   ```
   The generated `initrd.img` will be located in the `output/` directory.

3. Customize the kernel command line to include download parameters and attestation settings:
   ```
   initrd=initrd.img url=http://example.com/resource1,http://example.com/resource2 tpm_attestation=1 attestation_server=http://attestation.example.com
   ```

   Replace `http://example.com/resourceX` with the URLs of the files you want to download and provide the appropriate attestation server URL.

### Kernel Parameters

#### `url`
Comma-separated list of URLs to download. Example:
```
url=http://example.com/file1,http://example.com/file2
```

#### `output_dir`
Optional. Directory where files will be stored. Defaults to `/tmp`.

#### `aria2_options`
Optional. Custom aria2 options passed directly to the downloader. Example:
```
aria2_options="--max-concurrent-downloads=4 --timeout=60"
```

#### `tpm_attestation`
Optional. Enables TPM-based attestation when set to `1`. Example:
```
tpm_attestation=1
```

#### `attestation_server`
Required if `tpm_attestation=1`. Specifies the server to which TPM attestation data will be sent. Example:
```
attestation_server=http://attestation.example.com
```

#### `next_kernel_params`
Allows specifying kernel parameters for the next boot phase.

Example:
```
next_kernel_params="url=http://example.com/new-initrd.img new_param=value quiet"
```

During the boot process, the initrd will:
1. Parse `next_kernel_params` from the kernel command line.
2. Pass these parameters to the next kernel during the next boot phase, enabling workflows such as:
   - **Stateless Systems:** Dynamically configure the next kernel boot.
   - **Multiphase Boot Scenarios:** Apply different parameters for subsequent boot phases.

### TPM Attestation Workflow

1. Parse kernel parameters (`tpm_attestation` and `attestation_server`).
2. Initialize TPM and generate cryptographic keys.
3. Collect PCR values and create a nonce for the attestation process.
4. Generate a TPM quote and send it along with the attestation data to the specified `attestation_server`.
5. If the server responds with "OK", the boot process continues. Otherwise, the system halts.

## Testing

### Testing Download Functionality

Use [QEMU](https://www.qemu.org/) or another virtualization platform to test the generated initrd:
```bash
qemu-system-x86_64 -kernel /path/to/vmlinuz -initrd output/initrd.img -append "url=http://example.com/resource"
```

### Testing TPM Attestation

1. Run QEMU with attestation parameters:
   ```bash
   qemu-system-x86_64 -kernel /path/to/vmlinuz -initrd output/initrd.img -append "tpm_attestation=1 attestation_server=http://attestation.example.com"
   ```

2. Verify the attestation server receives the TPM quote and responds appropriately.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Inspired by the flexibility and power of `aria2`.
- Designed with HPC cluster bootstrapping, secure deployments, and custom workflows in mind.

