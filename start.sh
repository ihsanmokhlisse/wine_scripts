#!/bin/bash

### Wine packing script
### Version 1.1.6
### Author: Kron
### Email: kron4ek@gmail.com
### Link to latest version:
###		Yandex.Disk: https://yadi.sk/d/IrofgqFSqHsPu
###		Google.Drive: https://drive.google.com/open?id=1fTfJQhQSzlEkY-j3g0H6p4lwmQayUNSR
###		Github: https://github.com/Kron4ek/wine_scripts

#### Script for packing, distributing and launching Windows games
#### and programs in Linux using Wine. It works in all Linux
#### distributions which have bash shell and standard GNU utilities.

## Exit if root

if [[ "$EUID" = 0 ]]
  then echo "Do not run this script as root!"
  exit
fi

## Show help

if [ "$1" == "--help" ]; then
	clear
	echo -e "Available arguments:\n"
	echo -e "--debug\t\t\t\tenable Debug mode to see more information"
	echo -e "\t\t\t\tin output when the game starts."
	exit
fi

### Set variables

## Script directory

export SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
export DIR="$(dirname "$SCRIPT")"

## Wine executables

WINE="$DIR/wine/bin/wine"
WINE64="$DIR/wine/bin/wine64"
WINESERVER="$DIR/wine/bin/wineserver"

## Wine variables

export WINEPREFIX="$DIR/prefix"
export WINEDEBUG="-all"
export WINEDLLOVERRIDES="winemenubuilder.exe="

# Enable WINEDEBUG if --debug argument is passed to script
if [ "$1" = "--debug" ]; then export WINEDEBUG="err+all,fixme-all"; fi

## Script variables

# Get settings (variables) from settings file if exists
SCRIPT_NAME="$(basename "$SCRIPT" | cut -d. -f1)"
source "$DIR/settings_$SCRIPT_NAME"
source "$DIR/custom_vars"

# Generate settings file if it not exists or incomplete
if [ -z $CSMT_DISABLE ] || [ -z $DXVK ] || [ -z $USEPULSE ] || [ -z $PBA_DISABLE ]; then
	# Disables CSMT
	CSMT_DISABLE=0; echo "CSMT_DISABLE=$CSMT_DISABLE" > "$DIR/settings_$SCRIPT_NAME"
	# Enables DXVK (requires d3d11.dll and dxgi.dll)
	DXVK=1; echo "DXVK=$DXVK" >> "$DIR/settings_$SCRIPT_NAME"
	# Enables virtual desktop
	WINDOWED=0; echo "WINDOWED=$WINDOWED" >> "$DIR/settings_$SCRIPT_NAME"
	# Set virtual desktop size
	WINDOW_RES=800x600; echo "WINDOW_RES=$WINDOW_RES" >> "$DIR/settings_$SCRIPT_NAME"
	# Use PulseAudio instead of ALSA
	USEPULSE=0; echo "USEPULSE=$USEPULSE" >> "$DIR/settings_$SCRIPT_NAME"
	# Restore screen resolution after close game
	FIXRES=1; echo "FIXRES=$FIXRES" >> "$DIR/settings_$SCRIPT_NAME"
	# Use system Wine
	SYSWINE=0; echo "SYSWINE=$SYSWINE" >> "$DIR/settings_$SCRIPT_NAME"
	# Set windows version (win7, winxp, win2k)
	WINVER=win7; echo "WINVER=$WINVER" >> "$DIR/settings_$SCRIPT_NAME"
	# Set prefix architecture
	WINEARCH=win64; echo "WINEARCH=$WINEARCH" >> "$DIR/settings_$SCRIPT_NAME"
	echo >> "$DIR/settings_$SCRIPT_NAME"
	export WINEESYNC=1; echo "export WINEESYNC=$WINEESYNC" >> "$DIR/settings_$SCRIPT_NAME"
	export PBA_DISABLE=1; echo "export PBA_DISABLE=$PBA_DISABLE" >> "$DIR/settings_$SCRIPT_NAME"
	echo >> "$DIR/settings_$SCRIPT_NAME"
	echo "# You can also put custom variables in this file" >> "$DIR/settings_$SCRIPT_NAME"
fi

# Enable virtual desktop if WINDOWED env is set to 1 or --window argument is passed
if [ $WINDOWED = 1 ]; then
	export VIRTUAL_DESKTOP="explorer /desktop=Wine,$WINDOW_RES"
fi

# Get current screen resolution
if [ $FIXRES = 1 ]; then
	RESOLUTION="$(xrandr | grep \* | awk '{print $1}')"
fi

# Make Wine binaries executable
if [ -d "$DIR/wine" ] && [ ! -x "$DIR/wine/bin/wine" ]; then
	chmod -R 700 "$DIR/wine"
fi

# Use system Wine if no Wine found in the directory
if [ ! -f "$WINE" ] || [ $SYSWINE = 1 ]; then
	WINE=wine
	WINE64=wine64
	WINESERVER=wineserver

	SYSWINE=1

	# Increase file descriptors limit just in case
	ulimit -n 100000
fi

# Check if Wine has PBA or ESYNC features
mkdir "$DIR/temp_files"
if [ ! -f "$DIR/temp_files/pba_status" ]; then
	if grep PBA "$DIR/wine/lib/wine/wined3d.dll.so" || grep PBA "$DIR/wine/lib64/wine/wined3d.dll.so"; then
		echo "yes" > "$DIR/temp_files/pba_status"
	else
		echo "no" > "$DIR/temp_files/pba_status"
	fi
fi

if [ ! -f "$DIR/temp_files/esync_status" ]; then
	if grep ESYNC "$DIR/wine/lib/wine/ntdll.dll.so" || grep ESYNC "$DIR/wine/lib64/wine/ntdll.dll.so"; then
		echo "yes" > "$DIR/temp_files/esync_status"
	else
		echo "no" > "$DIR/temp_files/esync_status"
	fi
fi

if [ "$(cat "$DIR/temp_files/pba_status")" = "no" ] || [ $SYSWINE = 1 ]; then
	NO_PBA_FOUND=1
else NO_PBA_FOUND=0; fi

if [ "$(cat "$DIR/temp_files/esync_status")" = "no" ] || [ $SYSWINE = 1 ]; then
	NO_ESYNC_FOUND=1
else NO_ESYNC_FOUND=0; fi

# Disable ESYNC if ulimit fails
ESYNC_FORCE_OFF=0
if [ $NO_ESYNC_FOUND = 0 ] && [ $WINEESYNC = 1 ]; then
	if ! ulimit -n 100000; then
		export WINEESYNC=0
		ESYNC_FORCE_OFF=1
	fi
fi

## Game-specific variables

# Use game_info_SCRIPTNAME.txt file if exists
if [ -f "$DIR/game_info/game_info_$SCRIPT_NAME.txt" ]; then
	GAME_INFO="$(cat "$DIR/game_info/game_info_$SCRIPT_NAME.txt")"
else
	GAME_INFO="$(cat "$DIR/game_info/game_info.txt")"
fi

GAME="$(echo "$GAME_INFO" | sed -n 6p)"
VERSION="$(echo "$GAME_INFO" | sed -n 2p)"
GAME_PATH="$WINEPREFIX/drive_c/$(echo "$GAME_INFO" | sed -n 1p)"
EXE="$(echo "$GAME_INFO" | sed -n 3p)"
ARGS="$(echo "$GAME_INFO" | sed -n 4p)"

### Prepare for launching game

## Exit if there is no Wine

WINE_VERSION="$("$WINE" --version)"
if [ ! "$WINE_VERSION" ]; then
	clear
	echo "There is no Wine available in your system!"
	exit
fi

## Exit if there is no game_info.txt file

if [ ! "$GAME_INFO" ]; then
	clear
	echo "There is no game_info.txt file!"
	exit
fi

## Exit if user have no write permission on directory

if ! touch "$DIR/write_test"; then
	clear
	echo "You have no write permission on this directory!"
	echo
	echo "You can make directory writable by everyone with this command:"
	echo
	echo "chmod 777 DIRNAME"
	exit
fi
rm -f "$DIR/write_test"

## Change working directory

cd "$DIR" || exit

## Setup prefix

if [ ! -d prefix ] || [ "$(id -un)" != "$(cat temp_files/lastuser)" ] || [ "$WINE_VERSION" != "$(cat temp_files/lastwine)" ]; then
	# Move old prefix just in case
	mv prefix "prefix_$(date '+%d:%m_%H:%M:%S')"

	# Remove temp_files directory
	rm -r temp_files

	# Create prefix
	clear; echo "Creating prefix, please wait."

	export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree,mshtml="
	"$WINE" wineboot
	"$WINESERVER" -w
	export WINEDLLOVERRIDES="winemenubuilder.exe="

	# Create symlink to game directory
	mkdir -p "$GAME_PATH"; rm -r "$GAME_PATH"
	ln -sfr game_info/data "$GAME_PATH"

	# Execute files in game_info/exe directory
	if [ -d game_info/exe ]; then
		for file in game_info/exe/*; do
			clear; echo "Executing file $file"

			"$WINE" start "$file"
			"$WINESERVER" -w
		done
	fi

	# Apply reg files
	if [ -d game_info/regs ]; then
		for file in game_info/regs/*.reg; do
			"$WINE" regedit "$file"
			"$WINE64" regedit "$file"
		done
	fi

	# Symlink requeired dlls, override and register them
	if [ -d game_info/dlls ]; then
		echo -e "Windows Registry Editor Version 5.00\n" > dlloverrides.reg
		echo -e "[HKEY_CURRENT_USER\Software\Wine\DllOverrides]" >> dlloverrides.reg

		for x in game_info/dlls/*; do
			if [ ! -d "$x" ]; then
				ln -sfr "$x" "$WINEPREFIX/drive_c/windows/system32"

				# Do not override component if required
				if [ ! -f "game_info/dlls/nooverride/$(basename $x)" ]; then
					echo -e '"'$(basename $x .dll)'"="native"' >> dlloverrides.reg
				fi

				# Register component with regsvr32
				"$WINE" regsvr32 "$(basename $x)"
				"$WINE64" regsvr32 "$(basename $x)"
			fi
		done

		"$WINE" regedit dlloverrides.reg
		"$WINE64" regedit dlloverrides.reg
		rm dlloverrides.reg
	fi

	# Make documents directory
	if [ ! -d "$DIR/documents" ]; then
		mv "$WINEPREFIX/drive_c/users/$(id -un)" "$DIR/documents"
	fi
	rm -r "$WINEPREFIX/drive_c/users/$(id -un)"
	ln -sfr "$DIR/documents" "$WINEPREFIX/drive_c/users/$(id -un)"

	# Sandbox the prefix; Borrowed from winetricks scripts
	rm -f "$WINEPREFIX/dosdevices/z:"

	if cd "$WINEPREFIX/drive_c/users/$(id -un)"; then
		# Use one directory to all symlinks
		# This is necessarry for multilocale compatibility
		mkdir Documents_Multilocale

		for x in *; do
			if test -h "$x" && test -d "$x"; then
				rm -f "$x"
				ln -sfr Documents_Multilocale "$x"
			fi
		done

		cd "$DIR"
	fi

	"$WINE" regedit /D 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}'
	echo disable > "$WINEPREFIX/.update-timestamp"

	# Copy content from additional directories
	if [ -d game_info/additional ]; then
		for (( i=1; i <= $(ls -d game_info/additional/*/ | wc -l); i++ )); do
			ADD_PATH="$WINEPREFIX/drive_c/$(cat game_info/additional/path.txt | sed -n "$i"p | sed "s/--REPLACE_WITH_USERNAME--/$(id -un)/g")"

			mkdir -p "$ADD_PATH"

			if [ -f game_info/additional/dir_$i/dosymlink ]; then
				for file in game_info/additional/dir_$i/*; do
					if [ -d "$ADD_PATH/$(basename "$file")" ]; then
						rm -r "$ADD_PATH/$(basename "$file")"
					fi

					ln -sfr "$file" "$ADD_PATH"
				done
			else
				cp -r game_info/additional/dir_$i/* "$ADD_PATH"
			fi
		done
	fi

	# Execute scripts in game_info/sh directory
	if [ -d game_info/sh ]; then
		chmod -R 700 game_info/sh

		for file in game_info/sh/*.sh; do "$file"; done
	fi

	# Enable WINEDEBUG during first run
	export WINEDEBUG="err+all,fixme-all"

	# Save information about last user name and Wine version
	mkdir temp_files
	echo "$(id -un)" > temp_files/lastuser && echo "$WINE_VERSION" > temp_files/lastwine
fi

## Set windows version; Borrowed from winetricks

if [ "$WINVER" != "$(cat temp_files/lastwin)" ]; then
	if [ "$WINVER" = "winxp" ]; then
		csdversion="Service Pack 3"
		currentbuildnumber="2600"
		currentversion="5.1"
		csdversion_hex=dword:00000300
	elif [ "$WINVER" = "win2k" ]; then
		csdversion="Service Pack 4"
		currentbuildnumber="2195"
		currentversion="5.0"
		csdversion_hex=dword:00000400
	elif [ "$WINVER" = "win7" ]; then
		csdversion="Service Pack 1"
		currentbuildnumber="7601"
		currentversion="6.1"
		csdversion_hex=dword:00000100

		"$WINE" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
		"$WINE64" reg add "HKLM\\System\\CurrentControlSet\\Control\\ProductOptions" /v ProductType /d "WinNT" /f
	fi

	# Create registry file
	echo -e "Windows Registry Editor Version 5.00\n" > "$WINEPREFIX/drive_c/setwinver.reg"
	echo -e "[HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion]" >> "$WINEPREFIX/drive_c/setwinver.reg"
	echo -e '"CSDVersion"="'$csdversion'"' >> "$WINEPREFIX/drive_c/setwinver.reg"
	echo -e '"CurrentBuildNumber"="'$currentbuildnumber'"' >> "$WINEPREFIX/drive_c/setwinver.reg"
	echo -e '"CurrentVersion"="'$currentversion'"' >> "$WINEPREFIX/drive_c/setwinver.reg"

	echo -e "\n[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Windows]" >> "$WINEPREFIX/drive_c/setwinver.reg"
	echo -e '"CSDVersion"='$csdversion_hex'\n' >> "$WINEPREFIX/drive_c/setwinver.reg"

	# Apply and delete registry file
	"$WINE" regedit C:\setwinver.reg
	"$WINE64" regedit C:\setwinver.reg
	rm "$WINEPREFIX/drive_c/setwinver.reg"
	echo "$WINVER" > temp_files/lastwin
fi

## Set sound driver to PulseAudio; Borrowed from winetricks

if [ $USEPULSE = 1 ] && [ ! -f "$WINEPREFIX/drive_c/usepulse.reg" ]; then
	# Create registry file
	echo -e "Windows Registry Editor Version 5.00\n" > "$WINEPREFIX/drive_c/usepulse.reg"
	echo -e "[HKEY_CURRENT_USER\\Software\\Wine\\Drivers]\n" >> "$WINEPREFIX/drive_c/usepulse.reg"
	echo -e '"Audio"="pulse"' >> "$WINEPREFIX/drive_c/usepulse.reg"

	# Apply registry file
	"$WINE" regedit C:\usepulse.reg
	"$WINE64" regedit C:\usepulse.reg
	rm "$WINEPREFIX/drive_c/usealsa.reg"
elif [ $USEPULSE = 0 ] && [ ! -f "$WINEPREFIX/drive_c/usealsa.reg" ]; then
	# Create registry file
	echo -e "Windows Registry Editor Version 5.00\n" > "$WINEPREFIX/drive_c/usealsa.reg"
	echo -e "[HKEY_CURRENT_USER\\Software\\Wine\\Drivers]\n" >> "$WINEPREFIX/drive_c/usealsa.reg"
	echo -e '"Audio"="alsa"' >> "$WINEPREFIX/drive_c/usealsa.reg"

	# Apply registry file
	"$WINE" regedit C:\usealsa.reg
	"$WINE64" regedit C:\usealsa.reg
	rm "$WINEPREFIX/drive_c/usepulse.reg"
fi

## Disable CSMT if required

if [ $CSMT_DISABLE = 1 ] && [ ! -f "$WINEPREFIX/drive_c/csmt.reg" ]; then
	# Create registry file
	echo -e "Windows Registry Editor Version 5.00\n" > "$WINEPREFIX/drive_c/csmt.reg"
	echo -e "[HKEY_CURRENT_USER\Software\Wine\Direct3D]\n" >> "$WINEPREFIX/drive_c/csmt.reg"
	echo -e '"csmt"=dword:0\n' >> "$WINEPREFIX/drive_c/csmt.reg"

	# Apply registry file
	"$WINE" regedit C:\csmt.reg
	"$WINE64" regedit C:\csmt.reg
elif [ $CSMT_DISABLE = 0 ] && [ -f "$WINEPREFIX/drive_c/csmt.reg" ]; then
	# Create registry file
	echo -e "Windows Registry Editor Version 5.00\n" > "$WINEPREFIX/drive_c/csmt.reg"
	echo -e "[HKEY_CURRENT_USER\Software\Wine\Direct3D]\n" >> "$WINEPREFIX/drive_c/csmt.reg"
	echo -e '"csmt"=-' >> "$WINEPREFIX/drive_c/csmt.reg"

	# Apply registry file
	"$WINE" regedit C:\csmt.reg
	"$WINE64" regedit C:\csmt.reg
	rm "$WINEPREFIX/drive_c/csmt.reg"
fi

## Disable DXVK if required
## Also disable nvapi library if DXVK is enabled

if [ $DXVK = 0 ]; then
	export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;dxgi,d3d10,d3d10_1,d3d10core,d3d11=b"
elif [ $DXVK = 1 ] && [ -f "$DIR/game_info/dlls/dxgi.dll" ]; then
	export WINEDLLOVERRIDES="$WINEDLLOVERRIDES;nvapi64,nvapi="
fi

## Execute custom scripts

if [ -d game_info/sh/everytime ]; then
	for file in game_info/sh/everytime/*.sh; do "$file"; done
fi

## Run the game

# Output game, vars and Wine information
clear
echo "======================================================="
echo -e "\nGame: $GAME\nVersion: $VERSION"
echo -ne "\nWine: $WINE_VERSION"

if [ $SYSWINE = 1 ]; then echo -ne " (using system Wine)"; fi

echo -ne "\nArch: x$(echo $WINEARCH | tail -c 3)"

if [ ! -f "$DIR/game_info/dlls/dxgi.dll" ] || [ $DXVK = 0 ]; then
	if [ $CSMT_DISABLE = 1 ]; then echo -ne "\nCSMT: disabled"
	else echo -ne "\nCSMT: enabled"; fi

	if [ $NO_PBA_FOUND = 0 ]; then
		if [ $PBA_DISABLE = 1 ]; then echo -ne "\nPBA: disabled"
		else echo -ne "\nPBA: enabled"; fi
	fi

	if [ -f "$DIR/game_info/dlls/dxgi.dll" ]; then
		echo -ne "\nDXVK: disabled"
	fi
elif [ -f "$DIR/game_info/dlls/dxgi.dll" ]; then echo -ne "\nDXVK: enabled"; fi

if [ $NO_ESYNC_FOUND = 0 ]; then
	if [ $WINEESYNC = 1 ]; then echo -ne "\nESYNC: enabled"
	else echo -ne "\nESYNC: disabled"; fi

	if [ $ESYNC_FORCE_OFF = 1 ]; then echo -ne " (force disable; ulimit failed)"; fi
fi

echo -ne "\n\n======================================================="

if [ $NO_ESYNC_FOUND = 0 ] && [ $ESYNC_FORCE_OFF = 1 ]; then
	echo -ne "\n\nIf you want to enable ESYNC to improve game performance then"
	echo -ne "\nconfigure open file limit in /etc/security/limits.conf, add line:"
	echo -ne "\n\nUSERNAME hard nofile 150000"
	echo -ne "\n\nAnd then reboot your system."
	echo -ne "\n\n======================================================="
fi

if [ "$WINEDEBUG" = "-all" ]; then
	echo -ne "\n\nIf the game doesn't work, run it with --debug parameter"
	echo -ne "\nto see more information: ./start.sh --debug"
else
	echo -ne "\n\nDebug mode enabled!"
fi

echo -e "\n\n======================================================="
echo
echo "Output redirected to temp_files/start.log"
echo

# Launch the game
cd "$GAME_PATH/$(echo "$GAME_INFO" | sed -n 5p)" || exit
"$WINE" $VIRTUAL_DESKTOP "$EXE" $ARGS 2>> "$DIR/temp_files/start.log"

# Restore screen resolution
if [ $FIXRES = 1 ]; then
	"$WINESERVER" -w
	xrandr -s $RESOLUTION
fi
