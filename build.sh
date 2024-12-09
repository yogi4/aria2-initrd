#!/bin/bash
set -e
# Ensure output directory exists
mkdir -p /workspace/output

# Create initrd directory structure
mkdir -p initrd/{bin,sbin,etc,proc,sys,dev,tmp,var,usr/{bin,sbin},lib,usr/lib}

# Copy busybox and aria2 static binaries
cp /workspace/files/bin/busybox initrd/bin/
cp /workspace/files/bin/aria2c initrd/usr/bin/

# Create symlinks for busybox utilities
cd initrd/bin
for cmd in sh ls mkdir mount umount cat echo mknod ifconfig udhcpc wget \
           ln pwd sleep chmod chown route modprobe insmod rmmod depmod \
           lsmod sysctl free df; do
    ln -s busybox $cmd
done
cd -


# Copy aria2c binary
cp /workspace/files/bin/aria2c initrd/usr/bin/

# Copy kexec binary
cp /usr/sbin/kexec initrd/sbin/

# Copy curl binary
cp /usr/bin/curl initrd/usr/bin/

# Copy TPM2 tools binaries
cp /usr/bin/tpm2_* initrd/usr/bin/

# Copy D-Bus daemon (required for tpm2-abrmd)
cp /usr/bin/dbus-daemon initrd/usr/bin/

# Copy tpm2-abrmd daemon
cp /usr/sbin/tpm2-abrmd initrd/sbin/

# Copy D-Bus system configuration
cp /etc/dbus-1/system.conf initrd/etc/dbus-1/

# Copy necessary shared libraries for all binaries (copied earlier)
function copy_libs {
    for bin in "$@"; do
        ldd "$bin" | grep "=>" | awk '{print $3}' | xargs -I '{}' cp -v --parents '{}' initrd/
    done
}

copy_libs /workspace/files/bin/busybox \
          /workspace/files/bin/aria2c \
          /usr/sbin/kexec \
          /usr/bin/curl \
          /usr/bin/tpm2_pcrread \
          /usr/bin/dbus-daemon \
          /usr/sbin/tpm2-abrmd

# Add init script and configuration
cp /workspace/files/init initrd/
cp /workspace/files/etc/resolv.conf initrd/etc/


# Copy TPM2 tools and scripts into the initrd filesystem
cp /workspace/tpm_init.sh initrd/bin

# Add certificate bundle
mkdir -p initrd/etc/ssl
cp /workspace/files/etc/ssl/ca-bundle.crt initrd/etc/ssl/ca-bundle.crt


# Add minimal device nodes
mknod -m 666 initrd/dev/null c 1 3
mknod -m 666 initrd/dev/console c 5 1
mknod -m 666 initrd/dev/tty c 5 0
mknod -m 666 initrd/dev/random c 1 8
mknod -m 666 initrd/dev/urandom c 1 9
mknod -m 666 initrd/dev/zero c 1 10
mknod -m 666 initrd/dev/ptmx c 5 2

# Create device nodes for TPM in the initrd
mknod -m 666 initrd/dev/tpm0 c 10 224 || true
mknod -m 666 initrd/dev/tpmrm0 c 10 232 || true

# Create necessary directories for D-Bus and TPM2 Resource Manager
mkdir -p initrd/var/run/dbus
mkdir -p initrd/run

# Ensure all binaries are executable
chmod +x initrd/init
chmod +x files/bin/*
chmod +x initrd/usr/bin/*
chmod +x initrd/sbin/*
chmod +x initrd/bin/tpm_init.sh


# Create directories for TPM keys
mkdir -p initrd/etc/tpm


# Package initrd
cd initrd
find . | cpio -o -H newc | gzip > /workspace/output/custom-initrd.img
cd ..

echo "custom-initrd.img created successfully in /workspace/output/"
