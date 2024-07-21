#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  	echo "Please Run As Root."
  	return 1 2>/dev/null
	exit 1
fi

zenity --question --text="Create Snapshot Before Doing Anything?" --no-wrap
if [ $? = 0 ]; then
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")
	timeshift --create --comments "LM Primer - Automated Backup - $timestamp" --tags D

	if [ $? -eq 0 ]; then
	  	echo "Timeshift Snapshot Created Successfully."
	else
	  	echo "Failed To Create Timeshift Snapshot."
	  	return 1 2>/dev/null
		exit 1
	fi
else
	echo "[>] Skipped Snapshot Creation."
fi

zenity --question --text="Debloat?" --no-wrap
if [ $? = 0 ]; then
 	# These programs will be purged (delete from here if a program should stay)
	programs=(
	    redshift				# Screen Color adjustment tool for eye strain reduction
	    libreoffice-core		# Core components of LibreOffice
	    libreoffice-common		# Common files for LibreOffice
	    transmission-gtk		# BitTorrent client
	    hexchat			# Internet Relay Chat client
	    baobab			# Disk usage analyzer
	    seahorse		# GNOME frontend for GnuPG
	    thunderbird		# Email and news client
	    rhythmbox		# Music player
	    pix				# Image viewer and browser
	    simple-scan		# Scanning utility
	    drawing			# Drawing application
	    gnote			# Note-taking application
	    xreader			# Document viewer
	    onboard			# On-screen keyboard
	    celluloid			 # Video player
	    gnome-calendar		 # Calendar application
	    gnome-logs			 # Log viewer for the systemd 
	    gnome-power-manager	 # GNOME desktop Power management tool
	    warpinator			 # Tool for local network file sharing
	)

	for program in "${programs[@]}"; do
	    sudo apt purge "$program" -y
	done

 	# Remove residuals
	sudo apt autoremove -y && sudo apt clean

 	echo "[+] System Debloated."
else
	echo "[>] Skipped System Debloat."
fi

zenity --question --text "Prime For Portable Use?" --no-wrap
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

	# Power Saving for USB devices
	for i in /sys/bus/usb/devices/*/power/control; do
    	echo "auto" | sudo tee $i
	done

	# Disable Bluetooth on startup
	BT_CONF_FILE="/etc/bluetooth/main.conf"
	if [ ! -f "$BT_CONF_FILE" ]; then
    	echo "[!] Bluetooth Config Error: $BT_CONF_FILE Does Not Exist."
    	return 1 2>/dev/null
        exit 1
	fi

	sed -i 's/^AutoEnable=true/AutoEnable=false/' "$BT_CONF_FILE"

	if grep -q "^AutoEnable=false" "$BT_CONF_FILE"; then
    	echo "[+] Successfully Updated $BT_CONF_FILE. AutoEnable Is Now Set To <False>."
	else
    	echo "[!] Failed To Update $BT_CONF_FILE Or Setting 'AutoEnable=true' Was Not Found. Check Manually. Skipped."
	fi

	sudo sysctl -p

	# Install and configure preload for faster application launch
	sudo apt install -y preload
	sudo systemctl enable preload
	sudo systemctl start preload

 	# Remove residuals
	sudo apt autoremove -y && sudo apt clean

	echo "[+] Successfully Optimized For Portability."
else
	echo "[>] Skipped Optimization For Portability."
fi

zenity --question --text "[?] Halt And Remove Flatpak?" --no-wrap
if [ $? = 0 ]; then
	sudo apt purge flatpak
	sudo apt-mark hold flatpak
 	echo "[+] Disabled And Removed Flatpak."
else
	echo "[>] Skipped Flatpak Removal."
fi

zenity --question --text "[?] Optimize Boot Time?" --no-wrap
if [ $? = 0 ]; then
	# Decrease GRUB timeout
	sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=1/' /etc/default/grub
	# Disable GRUB submenu
	sed -i 's/#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub
	update-grub

	# Services start 'more concurrently'
	sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=40s/' /etc/systemd/system.conf
	sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=40s/' /etc/systemd/system.conf

	# Prefetching Boot-relevant files
	apt install -y systemd-readahead
	systemctl enable systemd-readahead-collect.service
	systemctl enable systemd-readahead-replay.service

 	echo "[+] Boot Optimization Successful."
else
	echo "[>] Skipped Boot Optimization."
fi

zenity --question --text "[?] Update The System?" --no-wrap
if [ $? = 0 ]; then
	sudo apt update && sudo apt upgrade -y
else
	echo "[>] Update Skipped."
fi

zenity --question --text "[?] Install Programs From List?" --no-wrap
if [ $? = 0 ]; then
	declare -A programs=(
		# Just some examples here really, modify this to your needs
	    ["Git"]="apt install -y git"
	    ["VLC"]="apt install -y vlc"
	    # ...
	)

	for program in "${!programs[@]}"; do
	    echo "Installing $program..."
	    if eval ${programs[$program]}; then
	        echo "[+] Installed $program."
	    else
	        echo "[-] Failed Installing $program."
	    fi
	done
else
	echo "[>] Skipped Program Installations."
fi

echo "[+] Script Finished."
echo "[>] Restart For Changes To Take Effect."
