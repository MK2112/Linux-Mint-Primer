#!/bin/bash

zenity --question --text="[?] Do you want to debloat your system?" --no-wrap
if [ $? = 0 ]; then
 	# These programs will be purged (delete from here if a program should stay)
	programs=(
	    redshift			# Screen Color adjustment tool for eye strain reduction
	    libreoffice-core		# Core components of LibreOffice
	    libreoffice-common		# Common files for LibreOffice
	    transmission-gtk		# BitTorrent client
	    hexchat			# Internet Relay Chat client
	    baobab			# Disk usage analyzer
	    seahorse			# GNOME frontend for GnuPG
	    thunderbird			# Email and news client
	    rhythmbox			# Music player
	    pix				# Image viewer and browser
	    simple-scan			# Scanning utility
	    drawing			# Drawing application
	    gnote			# Note-taking application
	    xreader			# Document viewer
	    onboard			# On-screen keyboard
	    celluloid			# Video player
	    gnome-calendar		# Calendar application
	    gnome-logs			# Log viewer for the systemd 
	    gnome-power-manager		# GNOME desktop Power management tool
	    warpinator			# Tool for local network file sharing
	)

	for program in "${programs[@]}"; do
	    sudo apt purge "$program" -y
	done

 	# Remove residuals
	sudo apt autoremove -y && sudo apt clean

 	echo "[+] System debloated."
else
	echo "[>] Skipped system debloat."
fi

zenity --question --text "[?] Do you want to configure your system for portable use?" --no-wrap
if [ $? = 0 ]; then
	# Install some optimization tools
 	sudo apt update && sudo apt upgrade -y
	sudo apt install -y tlp powertop thermald laptop-mode-tools cpufrequtils
	
	# Enable and start TLP for power management
	sudo systemctl enable tlp
	sudo systemctl start tlp
	
	# Configure powertop
	sudo powertop --auto-tune
	
	# Enable thermald for temperature management
	sudo systemctl enable thermald
	sudo systemctl start thermald
	
	# Enable laptop-mode-tools
	sudo systemctl enable laptop-mode
	sudo systemctl start laptop-mode
	
	# Set CPU governor to powersave
	for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
		echo "powersave" | sudo tee $cpu/cpufreq/scaling_governor
	done
	
	# Reduce 'swap temperature'
	echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
	
	# Improve memory management
	sudo apt install -y zram-config
	
	# Power saving for Intel GPU (if exists)
	if lspci | grep -i "VGA.*Intel" > /dev/null; then
		echo "options i915 enable_rc6=1 enable_fbc=1 semaphores=1" | sudo tee /etc/modprobe.d/i915.conf
	fi
	
	# Power saving for audio
	echo "options snd_hda_intel power_save=1" | sudo tee /etc/modprobe.d/audio_powersave.conf

    	# Turn off Wake-on-LAN
    	sudo ethtool -s eth0 wol d

    	# Enable SATA power management
    	for i in /sys/class/scsi_host/host*/link_power_management_policy; do
	        echo "min_power" | sudo tee $i
    	done

    	# Disable NMI watchdog
    	echo "kernel.nmi_watchdog = 0" | sudo tee -a /etc/sysctl.conf

    	# Enable power saving for USB devices
    	for i in /sys/bus/usb/devices/*/power/control; do
        	echo "auto" | sudo tee $i
    	done

    	# Disable Bluetooth on startup (Thinkpad-specfic)
    	sudo rfkill block bluetooth

    	# Disable Bluetooth on startup (general)
    	BT_CONF_FILE="/etc/bluetooth/main.conf"
    	if [ ! -f "$BT_CONF_FILE" ]; then
        	echo "[!] Bluetooth Config Error: $BT_CONF_FILE does not exist."
        	return 1
    	fi
    
    	if [ ! -w "$BT_CONF_FILE" ]; then
        	echo "[!] No write permission for $BT_CONF_FILE. Please run this script with sudo."
	        return 2
    	fi
    
    	sed -i 's/^AutoEnable=true/AutoEnable=false/' "$BT_CONF_FILE"
    
    	if grep -q "^AutoEnable=false" "$BT_CONF_FILE"; then
        	echo "[+] Successfully updated $BT_CONF_FILE. AutoEnable is now set to false."
    	else
        	echo "[!] Failed to update $BT_CONF_FILE or setting 'AutoEnable=true' was not found. Check manually. Skipped."
    	fi

    	# Apply sysctl changes
    	sudo sysctl -p

    	# Install and configure preload for faster application launch
    	sudo apt install -y preload
    	sudo systemctl enable preload
    	sudo systemctl start preload

     	# Remove residuals
	sudo apt autoremove -y && sudo apt clean

	echo "[+] System optimized for portability."
else
	echo "[>] Skipped system optimization for portability."
fi

zenity --question --text "[?] Do you want remove flatpak and mark it on hold?" --no-wrap
if [ $? = 0 ]; then
	# Purge and halt flatpak support of your system
	sudo apt purge flatpak
	sudo apt-mark hold flatpak

 	echo "[+] Disabled and removed Flatpak."
else
	echo "[>] Skipped Flatpak removal."
fi


zenity --question --text "[?] Would you like to update your system?" --no-wrap
if [ $? = 0 ]; then
	# Update and upgrade Linux Mint
	sudo apt update && sudo apt upgrade -y
 	echo "[+] Updated the system."
else
	echo "[>] Skipped system update."
fi

echo "[+] Script finished."
return 0
