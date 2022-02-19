#!/usr/bin/env bash
ask() {
    local prompt default reply

    if [[ ${2:-} = 'Y' ]]; then
        prompt='Y/n'
        default='Y'
    elif [[ ${2:-} = 'N' ]]; then
        prompt='y/N'
        default='N'
    else
        prompt='y/n'
        default=''
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read -r reply </dev/tty

        # Default?
        if [[ -z $reply ]]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
hwclock --systohc

# Language settings
sed 's/#en_US.UTF-8/en_US.UTF-8/g' -i /etc/locale.gen
sed 's/#de_DE.UTF-8/de_DE.UTF-8/g' -i /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_TIME=de_DE.UTF-8" >> /etc/locale.conf

# Set keyboard layout
#echo "KEYMAP=de-latin1" > /etc/vconsole.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "fichtls-artix-lap" > /etc/hostname

# Update pacman database and update packages
pacman -Syyu

# Install system relevant packages
pacman -S --noconfirm lvm2 lvm2-s6 cryptsetup dhcpcd dhcpcd-s6 iwd iwd-s6

if ask "Replace HOOKS in mkinitcpio.conf with LVM and encryption enabled?"; then
    sed 's/^HOOKS=.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/g' -i /etc/mkinitcpio.conf
    mkinitcpio -P
fi

# If using GRUB
if ask "(Currently broken: answer with no) Install GRUB?"; then
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    # TODO: get UUID of the encrypted device
    # ROOT_UUID=$(blkid | grep "LinuxVolumeGroup-root" | cut -f2 -d " " | grep -oP '"(.*?)"' | tr -d '"')
    ROOT_UUID=""
    sed "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet cryptdevice=UUID=${ROOT_UUID}:cryptlvm root=\/dev\/LinuxVolumeGroup\/root\"/g" -i /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    unset ROOT_UUID
fi

if ask "Change root password?"; then
    passwd
fi

echo "You can now exit the chroot and unmount this partition. Dont forget to change your boot priority"
