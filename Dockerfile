# Use AlmaLinux as the base image
FROM almalinux:9

# Set working directory
WORKDIR /workspace

# Install development tools and dependencies
RUN dnf install -y \
    dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    #&& dnf install -y \
    && dnf install -y --allowerasing \
    autoconf \
    automake \
    boost-devel \
    bzip2 \
    bzip2-devel \
    cpio \
    cppunit \
    diffutils \
    gcc \
    gcc-c++ \
    gettext \
    gettext-devel \
    git \
    glibc-static \
    gzip \
    kernel-devel \
    libgcrypt-devel \
    libtool \
    libxml2-devel \
    make \
    m4 \
    openssl-devel \
    sqlite-devel \
    tar \
    wget \
    which \
    xz \
    zlib-devel \
    # Adding TPM2 tools dependencies
    tpm2-tools \
    tpm2-tss \
    tpm2-abrmd \
    dbus \
    # Additional tools
    curl \
    kexec-tools \
    sudo \
    python3 \
    python3-pip \ 
    # install TPM Agent
    keylime-agent \
    iproute \
    # Busy box dependencies
    kernel-headers \
    kernel-devel \
    glibc-static \
    glibc-devel \
    make \
    gcc \
    gcc-c++ \
    iproute-devel \
    perl \
    && dnf clean all

# Create the directories we'll need
RUN mkdir -p /workspace/files/bin/
RUN mkdir -p /workspace/files/etc/
RUN mkdir -p /workspace/files/etc/keylime
RUN mkdir -p /workspace/files/var/lib/keylime/cv_ca # For the CA cert
# Allow root to use sudo without password
RUN echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# -----------------------------------------------------------------------
# 1) Build aria2 as a static binary
# -----------------------------------------------------------------------
RUN wget https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0.tar.gz \
    && tar -xzf aria2-1.36.0.tar.gz \
    && cd aria2-1.36.0 \
    && ./configure \
       CXXFLAGS="-std=c++11" \
       --enable-static \
       --disable-shared \
       --with-boost-libdir=/usr/lib64 \
       --with-boost=/usr/include/boost \
       --without-gnutls \
       --without-libgcrypt \
       --without-libexpat \
       --without-libuv \
       ARIA2_STATIC=yes \
    && make \
    && cp src/aria2c /workspace/files/bin/aria2c \
    && cd .. \
    && rm -rf aria2-1.36.0*


# -----------------------------------------------------------------------
# 2) Build BusyBox as a static binary
# -----------------------------------------------------------------------
#RUN git clone https://git.busybox.net/busybox \
#    && cd busybox \
#    && make defconfig \
#    && sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config \
#    && make -j$(nproc) \
#    && cp busybox /workspace/files/bin/busybox \
#    && cd .. \
#    && rm -rf busybox
 

RUN wget https://busybox.net/downloads/busybox-1.35.0.tar.bz2 \
    && tar -xjf busybox-1.35.0.tar.bz2 \
    && cd busybox-1.35.0 \
    && make defconfig \
    && sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config \
    && sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config \
    && make -j$(nproc) \
    && cp busybox /workspace/files/bin/busybox \
    && cd .. \
    && rm -rf busybox-1.35.0*


# Copy project files
COPY build.sh /workspace/build.sh
RUN mkdir -p /workspace/files/etc/
COPY init /workspace/files/init
#CODE for tpm_init
#COPY tpm_init.sh /workspace/tpm_init.sh
COPY ./etc/resolv.conf /workspace/files/etc/resolv.conf
COPY ./etc/resolv.conf /workspace/files/etc/resolv.conf
# Create necessary directories and download ca-bundle.crt
RUN mkdir -p /workspace/files/etc/ssl/ && \
    wget -O /workspace/files/etc/ssl/ca-bundle.crt https://curl.se/ca/cacert.pem


# Make the build script executable
RUN chmod +x /workspace/build.sh

# Add TPM initialization script
#COPY tpm_init.sh /workspace/tpm_init.sh
#RUN chmod +x /workspace/tpm_init.sh

USER root
# Define the entrypoint to run the build script
ENTRYPOINT ["/workspace/build.sh", "--allow-root"]

