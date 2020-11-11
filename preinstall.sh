#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Install Setup and Config with BTRFS on UEFI x86_64
#-------------------------------------------------------------------------

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download"
echo "-------------------------------------------------"
loadkeys de_CH-latin1
timedatectl set-ntp true
pacman -Syyy --noconfirm
pacman -S --noconfirm pacman-contrib wget
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# Downloads the complete mirrorlist of https servers and sorts them
# -e 's/^#Server/Server/' uncomments all servers | -e '/^#/d' deletes lines beginning with #
curl -s "https://www.archlinux.org/mirrorlist/?protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 6 - >/etc/pacman.d/mirrorlist

echo -e "\nInstalling prereqs...\n$HR"
pacman -S --noconfirm gptfdisk btrfs-progs

echo "-------------------------------------------------"
echo "-----------guided partitioning? (y)--------------"
echo "-------------------------------------------------"
read guidedPartitioning

if [[ $guidedPartitioning =~ y ]]; then
    echo "-------------------------------------------------"
    echo "-------select your disk to format----------------"
    echo "-------------------------------------------------"
    lsblk
    echo "Please enter disk: (example /dev/sda)"
    echo "Caution! This will erase the disk completly."
    read DISK
    echo "--------------------------------------"
    echo -e "\nFormatting disk...\n$HR"
    echo "--------------------------------------"

    # disk prep for further information to partitioning: man sgdisk
    sgdisk -Z ${DISK}         # zap all on disk
    sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1:0:+1000M ${DISK} # partition 1 (UEFI SYS), default start block, 512MB
    sgdisk -n 2:0:0 ${DISK}      # partition 2 (Root), default start, remaining

    # set partition types
    sgdisk -t 1:ef00 ${DISK}
    sgdisk -t 2:8300 ${DISK}

    # label partitions
    sgdisk -c 1:"UEFISYS" ${DISK}
    sgdisk -c 2:"ROOT" ${DISK}

    # make filesystems
    echo -e "\nCreating Filesystems...\n$HR"

    if [[ ${DISK} =~ nvme ]]; then
        DISK=${DISK}p
    fi

    mkfs.fat -F32 -n "UEFISYS" "${DISK}1"
    mkfs.btrfs -f -L "ROOT" "${DISK}2"

    # mount target
    mount "${DISK}2" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@snapshots
    umount /mnt
    mount -o noatime,compress=lzo,space_cache,subvol=@ "${DISK}2" /mnt
    mkdir -p /mnt/{boot,home,var,.snapshots}
    mount -o noatime,compress=lzo,space_cache,subvol=@home "${DISK}2" /mnt/home
    mount -o noatime,compress=lzo,space_cache,subvol=@var "${DISK}2" /mnt/var
    mount -o noatime,compress=lzo,space_cache,subvol=@snapshots "${DISK}2" /mnt/.snapshots
    mount -t vfat "${DISK}1" /mnt/boot/
else
    echo "--------------------------------------"
    echo "The script is now halted! Continue by pressing Enter after partitioning and mounting everything."
    echo "Change therefore the console with Ctrl + Alt + F2"
    echo "--------------------------------------"
    read waitingOnUser
fi

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
curl -s "https://www.archlinux.org/mirrorlist/?protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 6 - >/etc/pacman.d/mirrorlist
pacman -Syyy
pacstrap /mnt base base-devel linux linux-lts linux-firmware vim nano sudo grub grub-btrfs snapper zsh efibootmgr zsh-completions pacman-contrib curl git dosfstools mtools linux-headers wpa_supplicant --noconfirm --needed
genfstab -U /mnt >>/mnt/etc/fstab
cat /mnt/etc/fstab
cd /mnt/home
wget https://raw.githubusercontent.com/TheNFischer/ArchSway/master/preinstall-chroot.sh
arch-chroot /mnt /bin/bash -c "sh /home/preinstall-chroot.sh"

# preinstall-chroot.sh

umount -R /mnt

echo "--------------------------------------"
echo "--   SYSTEM READY FOR FIRST BOOT    --"
echo "--------------------------------------"
