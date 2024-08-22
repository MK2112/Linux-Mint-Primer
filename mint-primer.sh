#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  	echo "Please Run As Root."
  	return 1 2>/dev/null
	exit 1
fi

zenity --question --text="Create Snapshot?" --no-wrap
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
	    redshift			# Screen Color adjustment tool for eye strain reduction
	    libreoffice-core	# Core components of LibreOffice
	    libreoffice-common	# Common files for LibreOffice
	    transmission-gtk	# BitTorrent client
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

	sudo apt autoremove -y && sudo apt clean
 	echo "[+] System Debloated."
else
	echo "[>] Skipped System Debloat."
fi

zenity --question --text "Prime For Portable Use?" --no-wrap
if [ $? = 0 ]; then
	# TLP, Powertop, ThermalD - Install
 	sudo apt update && sudo apt upgrade -y
	sudo apt install -y tlp powertop thermald
	
	# Thermald - Enable and Start
	sudo systemctl enable thermald
	sudo systemctl start thermald

	# TLP - Enable and Start
	sudo systemctl enable tlp
	sudo systemctl start tlp
	
	# TLP - Configuration
	sudo sed -i \
 	-e 's/#TLP_ENABLE=0/TLP_ENABLE=1/' \
    	-e 's/#TLP_DEFAULT_MODE=AC/TLP_DEFAULT_MODE=AC/' \
    	-e 's/#TLP_PERSISTENT_DEFAULT=0/TLP_PERSISTENT_DEFAULT=0/' \
    	-e 's/#CPU_SCALING_GOVERNOR_ON_AC=performance/CPU_SCALING_GOVERNOR_ON_AC=performance/' \
    	-e 's/#CPU_SCALING_GOVERNOR_ON_BAT=powersave/CPU_SCALING_GOVERNOR_ON_BAT=powersave/' \
    	-e 's/#CPU_ENERGY_PERF_POLICY_ON_AC=performance/CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance/' \
    	-e 's/#CPU_ENERGY_PERF_POLICY_ON_BAT=powersave/CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power/' \
    	-e 's/#CPU_MIN_PERF_ON_AC=0/CPU_MIN_PERF_ON_AC=0/' \
    	-e 's/#CPU_MAX_PERF_ON_AC=100/CPU_MAX_PERF_ON_AC=100/' \
    	-e 's/#CPU_MIN_PERF_ON_BAT=0/CPU_MIN_PERF_ON_BAT=0/' \
    	-e 's/#CPU_MAX_PERF_ON_BAT=30/CPU_MAX_PERF_ON_BAT=60/' \
    	-e 's/#DISK_DEVICES="sda sdb"/DISK_DEVICES="sda"/' \
    	-e 's/#DISK_APM_LEVEL_ON_AC="254 254"/DISK_APM_LEVEL_ON_AC="254 254"/' \
    	-e 's/#DISK_APM_LEVEL_ON_BAT="128 128"/DISK_APM_LEVEL_ON_BAT="128 128"/' \
    	-e 's/#WIFI_PWR_ON_AC=off/WIFI_PWR_ON_AC=off/' \
    	-e 's/#WIFI_PWR_ON_BAT=on/WIFI_PWR_ON_BAT=on/' \
    	-e 's/#WOL_DISABLE=Y/WOL_DISABLE=Y/' \
    	-e 's/#SOUND_POWER_SAVE_ON_AC=0/SOUND_POWER_SAVE_ON_AC=0/' \
    	-e 's/#SOUND_POWER_SAVE_ON_BAT=1/SOUND_POWER_SAVE_ON_BAT=1/' \
    	-e 's/#RUNTIME_PM_ON_AC=on/RUNTIME_PM_ON_AC=on/' \
    	-e 's/#RUNTIME_PM_ON_BAT=auto/RUNTIME_PM_ON_BAT=auto/' \
    	/etc/tlp.conf

	# Disable Bluetooth on startup
	BT_CONF_FILE="/etc/bluetooth/main.conf"
	if [ ! -f "$BT_CONF_FILE" ]; then
    		echo "[!] Bluetooth Config Error: $BT_CONF_FILE Does Not Exist."
    		return 1 2>/dev/null
        	exit 1
	else
		sed -i 's/^AutoEnable=true/AutoEnable=false/' "$BT_CONF_FILE"
	fi

	if grep -q "^AutoEnable=false" "$BT_CONF_FILE"; then
    		echo "[+] Successfully Updated $BT_CONF_FILE. AutoEnable Is Now Set To <False>."
	else
    		echo "[!] Updating $BT_CONF_FILE Failed. Check Manually."
	fi

	# Install and configure preload for faster application launch
	sudo apt install -y preload
	sudo systemctl enable preload && sudo systemctl start preload
	sudo apt autoremove -y && sudo apt clean
 
	echo "[+] Successfully Optimized For Portability."
else
	echo "[>] Skipped Optimization For Portability."
fi

zenity --question --text "Halt And Remove Flatpak?" --no-wrap
if [ $? = 0 ]; then
	sudo apt purge flatpak
	sudo apt-mark hold flatpak
 	echo "[+] Disabled And Removed Flatpak."
else
	echo "[>] Skipped Flatpak Removal."
fi

zenity --question --text "Optimize Boot Time?" --no-wrap
if [ $? = 0 ]; then
    # Decrease GRUB timeout
    sudo sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=1/' /etc/default/grub
    # Disable GRUB submenu
    sudo sed -i 's/#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub
    # Disable GRUB Boot Animations
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet nosplash"/' /etc/default/grub
    sudo update-grub

    # Reduce tty count used during boot
    sudo sed -i 's/^#NAutoVTs=6/NAutoVTs=2/' /etc/systemd/logind.conf
    # Services start 'more concurrently'
    sudo sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=40s/' /etc/systemd/system.conf
    sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=40s/' /etc/systemd/system.conf
    # Systemd daemon-reload
    sudo systemctl daemon-reload

    echo "[+] Boot Optimization Successful."
else
    echo "[>] Skipped Boot Optimization."
fi

zenity --question --text "Disable Reporting and Telemetry?" --no-wrap
if [ $? = 0 ]; then
    firefox_config=$(find "/home/${SUDO_USER:-$USER}/.mozilla/firefox/" -name "*.default-release" -exec echo {}/prefs.js \;)
    if [ -f "$firefox_config" ]; then
        echo 'user_pref("toolkit.telemetry.enabled", false);' >> "$firefox_config"
        echo 'user_pref("toolkit.telemetry.unified", false);' >> "$firefox_config"
	echo 'user_pref("browser.region.update.enabled", false);' >> "$firefox_config"
	echo 'user_pref("extensions.getAddons.recommended.url", "");' >> "$firefox_config"
        echo 'user_pref("extensions.getAddons.cache.enabled", false);' >> "$firefox_config"
        echo 'user_pref("datareporting.healthreport.uploadEnabled", false);' >> "$firefox_config"
        echo 'user_pref("datareporting.policy.dataSubmissionEnabled", false);' >> "$firefox_config"
        echo 'user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);' >> "$firefox_config"
    else
        echo "Could not address Firefox. Configuration file not found."
    fi

    thunderbird_config=$(find "/home/${SUDO_USER:-$USER}/.thunderbird/" -name "*.default-esr" -exec echo {}/prefs.js \;)
    if [ -f "$thunderbird_config" ]; then
        echo 'user_pref("datareporting.healthreport.uploadEnabled", false);' >> "$thunderbird_config"
        echo 'user_pref("datareporting.policy.dataSubmissionEnabled", false);' >> "$thunderbird_config"
        echo 'user_pref("mail.shell.checkDefaultClient", false);' >> "$thunderbird_config"
        echo 'user_pref("mailnews.start_page.enabled", false);' >> "$thunderbird_config"
    else
        echo "Could not address Thunderbird. Configuration file not found."
    fi

    # Already false by default, just making sure
    gsettings set org.gnome.desktop.privacy send-software-usage-stats false
    gsettings set org.gnome.desktop.privacy report-technical-problems false
else
	echo "[>] Skipped Reporting and Telemetry."
fi

zenity --question --text "Update And Upgrade The System?" --no-wrap
if [ $? = 0 ]; then
	sudo apt update && sudo apt upgrade -y
else
	echo "[>] Skipped Update."
fi

zenity --question --text "Install Programs From List?" --no-wrap
if [ $? = 0 ]; then
    declare -A tools
    # Just some examples, modify to your needs
    tools["Git"]="apt install -y git"
    tools["Git-LFS"]="apt install -y git-lfs"
    tools["VLC"]="apt install -y vlc"
    tools["Flameshot"]="apt install -y flameshot"
    tools["PDFArranger"]="apt install -y pdfarranger"
    tools["OneDrive"]="apt install -y onedrive"
    tools["OBS"]="apt install -y obs-studio"
    tools["Audacity"]="apt install -y audacity"
    tools["Brasero"]="apt install -y brasero"
    tools["Kid3"]="apt install -y kid3"
    tools["Pinta"]="apt install -y pinta"
    tools["Remmina"]="apt install -y remmina"
    tools["NumLockX"]="apt install -y numlockx"

    for tool in "${!tools[@]}"; do
        echo "Installing $tool..."
        if eval ${tools[$tool]}; then
            echo "[+] Installed $tool."
            echo
        else
            echo "[-] Failed Installing $tool."
            echo
        fi
    done
else
    echo "[>] Skipped Program Installations."
fi

zenity --question --text "Script Finished. Reboot Now?" --no-wrap
if [ $? = 0 ]; then
	reboot
fi
