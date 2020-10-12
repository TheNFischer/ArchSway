#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Install Setup and Config with BTRFS on UEFI x86_64
#-------------------------------------------------------------------------

echo "--------------------------------------"
echo "--  Bootloader Grub Installation    --"
echo "--------------------------------------"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable grub-btrfs.path

echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager

echo "--------------------------------------"
echo "--          Snapper Setup           --"
echo "--------------------------------------"
umount /.snapshots/
rm -rf /.snapshots/
snapper -c root create-config /
groupadd snapper
sed -e 's/^ALLOW_GROUPS=""/ALLOW_GROUPS="snapper"/' /etc/snapper/configs/root > /etc/snapper/configs/root.new
mv /etc/snapper/configs/root.new /etc/snapper/configs/root
chmod a+rx /.snapshots/
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

echo "--------------------------------------"
echo "--      Set Password for Root       --"
echo "--------------------------------------"
echo "Enter password for root user: "
passwd root

exit