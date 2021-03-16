#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Install Setup and Config with BTRFS on UEFI x86_64
#-------------------------------------------------------------------------

echo "--------------------------------------"
echo "--        Language and time         --"
echo "--------------------------------------"
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc
sed -e 's/^#de_CH.UTF-8/de_CH.UTF-8/' /etc/locale.gen > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de_CH-latin1" > /etc/vconsole.conf
echo "arch-$RANDOM" > /etc/hostname

echo "--------------------------------------"
echo "--  Bootloader Grub Installation    --"
echo "--------------------------------------"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable grub-btrfs.path

echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager --noconfirm --needed
systemctl enable NetworkManager
systemctl enable sshd
# Systemd instead of Networkmanager
#systemctl enable systemd-resolved
#systemctl enable systemd-networkd.service
#rm /etc/resolv.conf
#ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "--------------------------------------"
echo "--      Set Password for Root       --"
echo "--------------------------------------"
echo "Enter password for root user: "
passwd root

# Adding User arch
groupadd snapper
useradd -m -G wheel,network,audio,log,input,kvm,video,users,snapper -s /bin/zsh arch
echo "--------------------------------------"
echo "--    Set Password for User arch    --"
echo "--------------------------------------"
echo "Enter password for user arch: "
passwd arch

# change sudoers file
echo "--------------------------------------"
echo "--        Check sudoers file        --"
echo "--------------------------------------"
#sed 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers | less
#echo "If sudoers file is correct, enter y"
#read sudoersOk
#if [[ $sudoersOk =~ y ]]; then
#    sed 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers > /etc/sudoers
#else
#    echo "Please configure file correctly with visudo and press enter."
#    read waitingOnUser
#fi
visudo

exit
