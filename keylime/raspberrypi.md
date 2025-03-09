Below is a **step-by-step** walkthrough for rebuilding the **raspberrypi2-6.6.51-20241008.v8.1.el9.src.rpm** kernel on an AlmaLinux 9–based Raspberry Pi so that **IMA** (`CONFIG_IMA=y`) is enabled. We’ll be using the **RPM build system** (`rpmbuild`), because you have a **.src.rpm**. Once built and installed, you’ll have a kernel RPM that you can boot on the Pi with IMA fully enabled.

---

## 1. Prerequisites

1. **Install RPM build tools and kernel build dependencies**:
   ```bash
   sudo dnf install -y rpm-build rpmdevtools \
       ncurses-devel bc bison flex elfutils-libelf-devel openssl-devel \
       dwarves python3-devel diffutils git patch
   ```
   - `rpm-build`, `rpmdevtools`: Tools to build RPM packages.  
   - `ncurses-devel`, `bc`, `bison`, `flex`, `elfutils-libelf-devel`, `openssl-devel`, `dwarves`, `python3-devel`: Common kernel build deps.

2. **Create** or **verify** your rpmbuild directory structure:
   ```bash
   rpmdev-setuptree
   ```
   This typically creates:
   ```
   ~/rpmbuild/
   ├─ SPECS
   ├─ SOURCES
   ├─ BUILD
   ├─ BUILDROOT
   ├─ RPMS
   └─ SRPMS
   ```
   You can also build as root under `/root/rpmbuild/` if that’s how your environment is set up, but generally non-root is recommended.

---

## 2. Install the Source RPM

1. **Place** the `raspberrypi2-6.6.51-20241008.v8.1.el9.src.rpm` file in a convenient directory.  
2. **Install** (unpack) the source RPM into your `rpmbuild` tree:
   ```bash
   rpm -ivh raspberrypi2-6.6.51-20241008.v8.1.el9.src.rpm
   ```
   This will copy the spec file into `SPECS/` and the source tarball / patches into `SOURCES/`.

3. **Change** into the SPECS directory:
   ```bash
   cd ~/rpmbuild/SPECS
   ```
   *(Or `/root/rpmbuild/SPECS` if building as root.)*

4. **List** the contents to see something like:
   ```bash
   ls
   raspberrypi2-kernel.spec
   ```
   or a similarly named spec file.

---

## 3. Prepare (Unpack) the Kernel Source

Run `rpmbuild -bp` on the spec file to **unpack** the source into `BUILD/`:

```bash
rpmbuild -bp --target=aarch64 raspberrypi2-kernel.spec
```

- `-bp` means “prepare,” i.e. apply patches and produce an unpacked tree in `~/rpmbuild/BUILD/<kernel-source-dir>`.
- `--target=aarch64` ensures we’re specifying the ARM64 architecture.

When it completes, check `~/rpmbuild/BUILD/` for a directory like:
```
~/rpmbuild/BUILD/linux-6.6.51-20241008.v8.1.el9/
```
(or a similar name). That’s your expanded kernel source.

---

## 4. Modify the Kernel Config to Enable IMA

### 4.1 Locate the Kernel Build Directory

Change into the newly unpacked build directory. For example:
```bash
cd ~/rpmbuild/BUILD/linux-6.6.51-20241008.v8.1.el9
```
*(Exact directory name may differ slightly. Adjust accordingly.)*

### 4.2 Load the Default .config

Often, the spec file or patches create a default `.config` in the build tree. If not, you can copy from your running kernel config:
```bash
cp /boot/config-$(uname -r) .config
```
Then:
```bash
make ARCH=arm64 olddefconfig
```
*(If `.config` already exists and is set up by the spec, you may skip this step.)*

### 4.3 Open menuconfig and Enable IMA

```bash
make ARCH=arm64 menuconfig
```
Then navigate:

1. `Security options  --->`
2. `    [*] Enable different security models`
3. `    [*] Integrity subsystem`
4. `        [*] IMA (Integrity Measurement Architecture) (CONFIG_IMA)`
   - Set **`(X)`** to `Y` (built‑in) or `M` (module). Usually `Y` is best.  
5. If you want appraisal:
   - `[*] IMA Appraise support (CONFIG_IMA_APPRAISE)`
   - `[*] IMA secure boot mode (CONFIG_IMA_SECURE_AND_OR_TRUSTED_BOOT)` (optional)  

You may also want:
- `CONFIG_IMA_MMAP_APPRAISE`
- `CONFIG_INTEGRITY_SIGNATURE` (if you want to do digital signature appraisals)
  
Save and exit. Now `.config` includes `CONFIG_IMA=y`.

### 4.4 Generate a Small Patch for the Config (Optional)

The RPM build process typically expects certain config fragments. If the spec file does an **auto merge** of config changes, you might be okay. If not, you may need to create a patch that sets `CONFIG_IMA=y` so that the RPM build can incorporate it automatically. A simple approach is to let it keep your updated `.config`, but be aware that the next step might overwrite it if the spec enforces a different config set.

For example, you could do:
```bash
diff -u .config-old .config > ~/rpmbuild/SOURCES/enable-ima.patch
```
Then add an entry in the spec to apply that patch. This depends on how the kernel packaging is structured. **If you skip it**, you’ll rely on your manually updated config to remain in the build tree for the next step.

---

## 5. Build the RPM

Return to the `SPECS` directory (or you can run from anywhere, specifying the spec file path). We’ll do a full build (`-ba` builds both the binary RPMs and the source RPM again):

```bash
cd ~/rpmbuild/SPECS
rpmbuild -ba --target=aarch64 raspberrypi2-kernel.spec
```

**Watch** for the build logs. The build process can take a long time on the Pi. Eventually, if all goes well, you’ll have packages in:
```
~/rpmbuild/RPMS/aarch64/
    ├─ kernel-raspberrypi2-6.6.51-20241008.v8.1.el9.aarch64.rpm
    ├─ kernel-raspberrypi2-devel-6.6.51-20241008.v8.1.el9.aarch64.rpm
    └─ ...
```
*(File names may differ. Look for something referencing `6.6.51`.)*

**If** the build overwrote your `.config` changes, you’ll need to either incorporate them as a patch or specify the `%config` approach in the spec. Some official kernel specs auto-merge config fragments. Check the build output carefully for lines that mention “CONFIG_IMA not found” or “CONFIG_IMA is disabled.” If that happens, you’ll need to create a small patch or config fragment. 

---

## 6. Install the New Kernel RPM

Once built, **install** your newly made kernel:

```bash
sudo dnf install ~/rpmbuild/RPMS/aarch64/kernel-raspberrypi2-6.6.51-20241008.v8.1.el9.aarch64.rpm
```

This places the new kernel files in `/boot/`, along with a config in `/boot/config-6.6.51-20241008.v8.1.el9` and modules in `/lib/modules/6.6.51-20241008.v8.1.el9/`.

---

## 7. Update Your Pi’s Bootloader Config

Depending on how AlmaLinux is set up for your Pi:

1. **If you’re using U-Boot or GRUB**: The new kernel might appear as an additional boot entry. Check `/boot/grub2/grub.cfg` or `/boot/efi/EFI/almalinux/`.  

2. **If you’re using `cmdline.txt`** (classic Raspberry Pi firmware approach):
   - The newly installed kernel might be named something like `vmlinuz-6.6.51-20241008.v8.1.el9.aarch64`.
   - You may need to copy or symlink it to `kernel8.img` or update `config.txt` with:
     ```ini
     [pi4]
     kernel=vmlinuz-6.6.51-20241008.v8.1.el9.aarch64
     arm_64bit=1
     ```
   - Then ensure your device tree (DTB) references are correct in `/boot/` or `config.txt`.

3. **(Optional)** If you want to enable IMA on the new kernel, append parameters to your boot command line (in `cmdline.txt` or GRUB’s `linux` line):
   ```text
   ima_policy=tcb ima_template=ima-ng ima_appraise=fix
   ```
   so it looks something like:
   ```text
   console=serial0,115200 root=/dev/mmcblk0p2 rw ... ima_policy=tcb ima_template=ima-ng ima_appraise=fix
   ```

---

## 8. Reboot and Verify

1. **Reboot**:
   ```bash
   sudo reboot
   ```
2. **Check** the kernel version:
   ```bash
   uname -r
   ```
   It should match `6.6.51-20241008.v8.1.el9`.
3. **Confirm** IMA is built in:
   ```bash
   zgrep CONFIG_IMA /proc/config.gz
   ```
   (or `cat /boot/config-$(uname -r) | grep IMA`)

   You want to see:
   ```
   CONFIG_IMA=y
   ```
4. If you appended the `ima_...` parameters, see if `/sys/kernel/security/ima` exists:
   ```bash
   ls /sys/kernel/security/ima
   ```
   And check dmesg for IMA logs:
   ```bash
   dmesg | grep IMA
   ```

If all is well, you have a **custom kernel with IMA enabled**.

---

## 9. Troubleshooting

1. **Spec Overwriting Config**: If your final kernel ends up missing `CONFIG_IMA=y`, examine the build logs for mention of “overriding .config” or “config-fragments.”  
   - You may need to create a small patch or `config-ima` fragment in `SOURCES/` that forces `CONFIG_IMA=y`, then reference it in the spec.  

2. **Boot Fails**: Keep an old, known-good kernel installed. If your Pi doesn’t boot, you can revert to the old kernel.  

3. **Long Build Times**: Consider cross-compiling on a faster x86 machine. Then you’d create an aarch64 RPM that can be installed on the Pi.

---

### Summary

1. **Install dev tools** and **unpack** the source RPM with `rpm -ivh`.  
2. **Prepare** with `rpmbuild -bp` to get a fully patched kernel source in `BUILD/`.  
3. **Enable** `CONFIG_IMA=y` in `.config` via `make ARCH=arm64 menuconfig`.  
4. **Build** the kernel RPM with `rpmbuild -ba`.  
5. **Install** the resulting kernel RPM with `dnf install`.  
6. **Adjust** your Pi’s bootloader or `cmdline.txt` to load the new kernel.  
7. **Reboot** and verify `CONFIG_IMA=y`.  

That’s it! You’ll then have a Pi kernel that supports IMA at runtime. Once that’s working, you can set up the kernel command line (`ima_policy=tcb ima_template=ima-ng`, etc.) and an `/etc/ima/ima-policy` file to measure or appraise system binaries.





make ARCH=arm64 menuconfig
   77  diff -u .config.old .config > ~/rpmbuild/SOURCES/enable-ima.patch
   78  cd ~/rpmbuild/SPECS
   79  vi raspberrypi2.spec 
   80  cat ~/rpmbuild/SOURCES/enable-ima.patch
   81  vi ../BUILD/linux-stable_20241008/.config
   82  cp ../BUILD/linux-stable_20241008/.config ~/rpmbuild/.config.backup
   83  rpmbuild -ba --target=aarch64 raspberrypi2.spec
   84  rpmbuild -ba --target=aarch64 raspberrypi2.spec
   85  ls /root/rpmbuild/RPMS/aarch64/
   86  vi /root/rpmbuild/BUILD/linux-stable_20241008/.config

Kernel reimaging helpful commands 

dnf repoquery --list raspberrypi2-kernel4 | grep kernel-6.6.51

Reinstall modified kernel

sudo dnf reinstall /root/rpmbuild/RPMS/aarch64/raspberrypi2-kernel4-6.6.51-20241008.v8.1.el9.aarch64.rpm

sudo dracut --force /boot/initramfs-6.6.51-20241008.v8.1.el9.img 6.6.51-20241008.v8.1.el9

Raspberry pi images 

https://cdimage.debian.org/mirror/almalinux.org/9.5/BaseOS/aarch64/os/

https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/assembly_ensuring-system-integrity-with-keylime_security-hardening#proc_deploying-keylime-for-runtime-monitoring_assembly_ensuring-system-integrity-with-keylime

https://documentation.suse.com/sle-micro/6.0/html/Micro-keylime/index.html


Helpful commands for registrar 

systemctl enable --now keylime_registrar
 systemctl status keylime_registrar

#on Agent
 systemctl enable --now keylime_agent
 systemctl status keylime_agent

#Onserver
 keylime_tenant -c regstatus --uuid bb248e67-152f-43b0-b467-a8ade446e7f7



 Setup On RHEL 
sudo dnf -y install tpm2-tools
 sudo dnf -y install tpm2-abrmd