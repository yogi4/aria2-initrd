# aria2-initrd

A minimal initrd implementation using `aria2` for downloading files during the early boot process. This project is designed for environments where fetching large files (e.g., container images or boot configurations) from remote sources is essential.

## Features

- **Containerized Build Process:** Uses a Docker container to ensure a consistent and reproducible build environment.
- **Efficient File Downloads:** Utilizes [aria2](https://github.com/aria2/aria2), a lightweight and high-performance download utility supporting HTTP(S), FTP, and BitTorrent protocols.
- **Lightweight Design:** Aimed at minimal environments, keeping the initrd as small as possible.
- **Highly Configurable:** Supports passing custom download URLs and options through kernel parameters.
- **Parallelism:** Leverages aria2's ability to perform concurrent downloads for faster bootstrapping.

## Use Cases

- **HPC Cluster Bootstrapping:** Fetching configuration files or images for stateless node setups.
- **Diskless Systems:** Loading operating system components or tools directly into memory.
- **Custom Deployment Workflows:** Downloading initialization resources for custom boot environments.

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

3. Customize the kernel command line to include download parameters:
   ```
   initrd=initrd.img url=http://example.com/resource1,http://example.com/resource2
   ```

   Replace `http://example.com/resourceX` with the URLs of the files you want to download.

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

#### `next_kernel_params`
This parameter allows you to specify kernel parameters for the next boot phase.

Example:
```
next_kernel_params="url=http://example.com/new-initrd.img new_param=value quiet"
```

During the boot process, the initrd will:
1. Parse `next_kernel_params` from the kernel command line.
2. Pass these parameters to the next kernel during the next boot phase, enabling workflows such as:
   - **Stateless Systems:** Dynamically configure the next kernel boot.
   - **Multiphase Boot Scenarios:** Apply different parameters for subsequent boot phases.


# Testing

1. Use [QEMU](https://www.qemu.org/) or another virtualization platform to test the generated initrd:
   ```bash
   qemu-system-x86_64 -kernel /path/to/vmlinuz -initrd output/initrd.img -append "url=http://example.com/resource"
   ```

2. Monitor the output logs to confirm the download process.


## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Inspired by the flexibility and power of `aria2`.
- Designed with HPC cluster bootstrapping and custom deployments in mind.
