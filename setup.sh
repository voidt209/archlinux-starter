#!/bin/bash

# ============================================
# Arch Linux Setup Script
# ============================================

echo "========================================="
echo "Arch Linux Interactive Setup Script"
echo "========================================="
echo "I will ask you step by step."
echo "You decide what to do at each step."
echo ""

# ============================================
# Step 1: Partition (ask before doing anything)
# ============================================
echo "--- Step 1: Disk Partition ---"
lsblk
echo ""
read -p "Do you want to partition a disk? (y/n): " do_partition

if [ "$do_partition" = "y" ]; then
    read -p "Enter disk name (e.g., /dev/sda): " disk
    echo "Which partition tool?"
    echo "1) fdisk (manual)"
    echo "2) parted (manual)"
    echo "3) cfdisk (menu)"
    read -p "Choose [1-3]: " tool

    case $tool in
        1) fdisk "$disk" ;;
        2) parted "$disk" ;;
        3) cfdisk "$disk" ;;
        *) echo "Skipped partition" ;;
    esac
else
    echo "Skipping disk partition."
fi

echo ""
read -p "Press Enter to continue..."

# ============================================
# Step 2: Mount (ask)
# ============================================
echo ""
echo "--- Step 2: Mount Partition ---"
lsblk
read -p "Enter root partition (e.g., /dev/sda2): " root_part
read -p "Enter boot/efi partition (optional, press Enter to skip): " boot_part

mount "$root_part" /mnt

if [ -n "$boot_part" ]; then
    mkdir -p /mnt/boot
    mount "$boot_part" /mnt/boot
    echo "Boot partition mounted at /mnt/boot"
fi

echo "Root mounted at /mnt"
read -p "Press Enter to continue..."

# ============================================
# Step 3: Install base packages (ask)
# ============================================
echo ""
echo "--- Step 3: Install Base Packages ---"
read -p "Do you want to run pacstrap? (y/n): " do_pacstrap

if [ "$do_pacstrap" = "y" ]; then
    echo "Recommended: base linux linux-firmware vim sudo grub"
    read -p "Enter packages to install: " packages
    pacstrap /mnt $packages
else
    echo "Skipping package installation."
fi

read -p "Press Enter to continue..."

# ============================================
# Step 4: Generate fstab (ask)
# ============================================
echo ""
echo "--- Step 4: Generate fstab ---"
read -p "Generate fstab? (y/n): " do_fstab

if [ "$do_fstab" = "y" ]; then
    genfstab -U /mnt >> /mnt/etc/fstab
    echo "fstab generated at /mnt/etc/fstab"
    cat /mnt/etc/fstab
else
    echo "Skipping fstab generation."
fi

read -p "Press Enter to continue..."

# ============================================
# Step 5: Basic settings (timezone, locale, hostname)
# ============================================
echo ""
echo "--- Step 5: Basic Settings ---"
read -p "Do basic settings (timezone/locale/hostname)? (y/n): " do_basic

if [ "$do_basic" = "y" ]; then
    cat > /mnt/basic_setup.sh << 'EOF'
#!/bin/bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
read -p "Enter hostname: " hn
echo "$hn" > /etc/hostname
echo "Root password:"
passwd
EOF
    chmod +x /mnt/basic_setup.sh
    arch-chroot /mnt /basic_setup.sh
    rm /mnt/basic_setup.sh
else
    echo "Skipping basic settings."
fi

read -p "Press Enter to continue..."

# ============================================
# Step 6: Desktop / WM (ask, optional)
# ============================================
echo ""
echo "--- Step 6: Desktop or Window Manager ---"
echo "1) None"
echo "2) KDE Plasma"
echo "3) GNOME"
echo "4) XFCE"
echo "5) i3wm"
echo "6) Sway"
read -p "Choose [1-6]: " de

if [ "$de" != "1" ]; then
    cat > /mnt/install_de.sh << 'EOF'
#!/bin/bash
case $1 in
    2) pacman -S --noconfirm plasma sddm; systemctl enable sddm ;;
    3) pacman -S --noconfirm gnome gdm; systemctl enable gdm ;;
    4) pacman -S --noconfirm xfce4 lightdm; systemctl enable lightdm ;;
    5) pacman -S --noconfirm i3-wm i3status dmenu ;;
    6) pacman -S --noconfirm sway foot ;;
    *) echo "Nothing installed" ;;
esac
EOF
    chmod +x /mnt/install_de.sh
    arch-chroot /mnt /mnt/install_de.sh "$de"
    rm /mnt/install_de.sh
else
    echo "Skipping desktop/WM installation."
fi

# ============================================
# Step 7: User (ask)
# ============================================
echo ""
read -p "Create a normal user? (y/n): " do_user

if [ "$do_user" = "y" ]; then
    cat > /mnt/create_user.sh << 'EOF'
#!/bin/bash
read -p "Username: " un
useradd -m -G wheel "$un"
passwd "$un"
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
EOF
    chmod +x /mnt/create_user.sh
    arch-chroot /mnt /mnt/create_user.sh
    rm /mnt/create_user.sh
fi

# ============================================
# Final
# ============================================
echo ""
echo "========================================="
echo "Setup finished"
echo "You can now:"
echo "  umount -R /mnt"
echo "  reboot"
echo "========================================="
