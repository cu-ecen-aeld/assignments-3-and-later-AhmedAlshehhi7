#!/bin/bash
# manual-linux.sh
# This script builds a barebones Linux kernel and root filesystem using an ARM cross-compile toolchain,
# and prepares the output for booting in QEMU.
# It runs non-interactively (except for required sudo operations).
# Author: [Your Name]

set -e
set -u

# 1. Set Variables:
OUTDIR=${1:-/tmp/aeld}                       # Output directory (default: /tmp/aeld)
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
# Set FINDER_APP_DIR to the absolute path of your finder-app directory.
# In GitHub Actions, the repository is checked out into the working directory.
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64

# For GitHub Actions, the cross-compiler is installed at:
# /usr/local/arm-cross-compiler/install/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/
# If running locally, adjust this path accordingly.
if [ -d "/usr/local/arm-cross-compiler/install/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin" ]; then
    CROSS_COMPILE=/usr/local/arm-cross-compiler/install/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
else
    # Fallback to local path (update as needed)
    CROSS_COMPILE=/home/ahmed/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
fi

echo "Using output directory: ${OUTDIR}"
echo "Using CROSS_COMPILE: ${CROSS_COMPILE}"
mkdir -p "${OUTDIR}" || { echo "Failed to create ${OUTDIR}"; exit 1; }
cd "${OUTDIR}"

# 2. Clone the Linux Kernel Source (if not present)
if [ ! -d "${OUTDIR}/linux" ]; then
    echo "Cloning Linux kernel version ${KERNEL_VERSION} into ${OUTDIR}"
    git clone --depth 1 --branch ${KERNEL_VERSION} ${KERNEL_REPO} linux
fi

# 3. Build the Kernel (if the Image doesn't exist)
if [ ! -e "${OUTDIR}/linux/arch/${ARCH}/boot/Image" ]; then
    cd linux
    echo "Checking out kernel version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    echo "Cleaning kernel tree"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    echo "Generating default config (defconfig)"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    echo "Building kernel Image..."
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
    cd "${OUTDIR}"
fi

# 4. Copy the Kernel Image to OUTDIR
if [ -f "${OUTDIR}/linux/arch/${ARCH}/boot/Image" ]; then
    echo "Copying kernel image to ${OUTDIR}/Image"
    cp "${OUTDIR}/linux/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"
else
    echo "Error: Kernel image not found!"
    exit 1
fi

# 5. Create the Root Filesystem (rootfs) Structure
echo "Creating root filesystem in ${OUTDIR}/rootfs"
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "Removing existing rootfs at ${OUTDIR}/rootfs"
    sudo rm -rf "${OUTDIR}/rootfs"
fi
if mountpoint -q "${OUTDIR}/rootfs/sys"; then
    echo "Unmounting ${OUTDIR}/rootfs/sys"
    sudo umount "${OUTDIR}/rootfs/sys"
fi
mkdir -p "${OUTDIR}/rootfs"
mkdir -p "${OUTDIR}/rootfs"/{bin,dev,etc,home,lib,lib64,proc,sys,sbin,tmp,usr,var}
mkdir -p "${OUTDIR}/rootfs"/usr/{bin,lib,sbin}
mkdir -p "${OUTDIR}/rootfs"/var/log

# 6. Build and Install BusyBox
cd "${OUTDIR}"
if [ ! -d "busybox" ]; then
    echo "Cloning BusyBox"
    git clone git://busybox.net/busybox.git
fi
cd busybox
git checkout ${BUSYBOX_VERSION}
make distclean
make defconfig
echo "Building BusyBox..."
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
echo "Installing BusyBox into rootfs..."
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install CONFIG_PREFIX="${OUTDIR}/rootfs"

# 7. Add Library Dependencies
echo "Adding necessary libraries to rootfs"
SYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)
cp -L "${SYSROOT}"/lib/ld-linux-aarch64.so.1 "${OUTDIR}/rootfs/lib/"
if [ -d "${SYSROOT}/lib64" ]; then
    cp -L "${SYSROOT}"/lib64/libm.so.6 "${OUTDIR}/rootfs/lib64/"
    cp -L "${SYSROOT}"/lib64/libresolv.so.2 "${OUTDIR}/rootfs/lib64/"
    cp -L "${SYSROOT}"/lib64/libc.so.6 "${OUTDIR}/rootfs/lib64/"
fi

# 8. Create Device Nodes
echo "Creating device nodes in rootfs (sudo may be required)"
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3
sudo mknod -m 600 "${OUTDIR}/rootfs/dev/console" c 5 1

# 9. Build and Copy the Writer Application from Finder App
echo "Building writer application from finder-app"
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
echo "Copying writer to rootfs/home"
cp writer "${OUTDIR}/rootfs/home/"

# 10. Copy Finder Scripts and Configuration Files
echo "Copying finder scripts and configuration files to rootfs/home"
# Create a conf directory inside /home for configuration files.
mkdir -p "${OUTDIR}/rootfs/home/conf"
cp "${FINDER_APP_DIR}/finder.sh" "${OUTDIR}/rootfs/home/"
sudo chmod +x "${OUTDIR}/rootfs/home/finder.sh"
cp "${FINDER_APP_DIR}/conf/username.txt" "${OUTDIR}/rootfs/home/conf/"
cp "${FINDER_APP_DIR}/conf/assignment.txt" "${OUTDIR}/rootfs/home/conf/"
cp "${FINDER_APP_DIR}/finder-test.sh" "${OUTDIR}/rootfs/home/"
sudo chmod +x "${OUTDIR}/rootfs/home/finder-test.sh"
cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${OUTDIR}/rootfs/home/"

# Debug: List the contents of /home in the rootfs
echo "Contents of rootfs/home:"
ls -l "${OUTDIR}/rootfs/home"

# Update finder-test.sh to reference the correct paths:
# Replace '../conf/assignment.txt' with '/home/conf/assignment.txt'
sed -i 's|\.\./conf/assignment.txt|/home/conf/assignment.txt|g' "${OUTDIR}/rootfs/home/finder-test.sh"
# Replace '../finder-app/writer' with './writer'
sed -i 's|\.\./finder-app/writer|./writer|g' "${OUTDIR}/rootfs/home/finder-test.sh"
# Force finder-test.sh to call finder.sh using absolute path
sed -i 's|\./finder.sh|/home/finder.sh|g' "${OUTDIR}/rootfs/home/finder-test.sh"

# 11. Set Ownership of the Root Filesystem
echo "Setting ownership of rootfs to root"
sudo chown -R root:root "${OUTDIR}/rootfs"

# 12. Create the Initramfs Archive
echo "Creating initramfs archive"
cd "${OUTDIR}/rootfs"
find . | cpio -o --format=newc | gzip > "${OUTDIR}/initramfs.cpio.gz"
if [ ! -f "${OUTDIR}/initramfs.cpio.gz" ]; then
    echo "Error: Initramfs archive not created"
    exit 1
fi

echo "Build complete!"
echo "Kernel image: ${OUTDIR}/Image"
echo "Initramfs archive: ${OUTDIR}/initramfs.cpio.gz"

