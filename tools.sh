#!/bin/bash

### Tools script for "Wine packing script"
### Version 1.0.1
### Author: Kron
### Email: kron4ek@gmail.com
### Link to latest version:
###		Yandex.Disk: https://yadi.sk/d/IrofgqFSqHsPu
###		Google.Drive: https://drive.google.com/open?id=1fTfJQhQSzlEkY-j3g0H6p4lwmQayUNSR
###		Github: https://github.com/Kron4ek/wine_scripts

#### Script for launching Wine tools such as winecfg, regedit
#### and winefile. Also this script can cleanup directory from
#### unnecessary file, create icons in Applications Menu and Desktop
#### and kill all processes in preifx.  This script is helper for
#### "Wine packing script".

## Exit if root

if [[ "$EUID" = 0 ]]
  then echo "Do not run this script as root!"
  exit
fi

## Show help

if [ "$1" = "--help" ] || [ ! "$1" ]; then
	clear
	echo -e "Available arguments:\n"
	echo -e "--cfq\t\t\trun winecfg"
	echo -e "--reg\t\t\trun regedit"
	echo -e "--fm\t\t\trun Wine file manager"
	echo -e "--kill\t\t\tkill all running processes in prefix"
	echo -e "--clean\t\t\tremove almost all unnecessarry files"
	echo -e "\t\t\tfrom directory"
	echo -e "--icons\t\t\tcreate icons to run the game"
	echo -e "\t\t\tin Desktop and Applications menu"
	echo -e "--remove-icons\t\tremove created icons"
	exit
fi

export SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
export DIR="$(dirname "$SCRIPT")"

## Wine executables

export WINE="$DIR/wine/bin/wine"
export WINESERVER="$DIR/wine/bin/wineserver"

export WINEPREFIX="$DIR/prefix"
export WINEDEBUG="-all"
export WINEDLLOVERRIDES="winemenubuilder.exe="

# Get settings from settings file
SYSWINE=0
source "$DIR/settings_start"

# Use system Wine if no Wine found in the directory
if [ ! -f "$WINE" ] || [ $SYSWINE = 1 ]; then
	export WINE=wine
	export WINESERVER=wineserver

	SYSWINE=1

	# Increase file descriptors limit just in case
	ulimit -n 100000
fi

cd "$DIR" || exit

shopt -s extglob

if [ "$1" = "--clean" ]; then
	if [ ! -d "$DIR/game_info/data" ] || [ ! -f "$DIR/start.sh" ]; then exit; fi

	rm -rf !(game_info|wine*|*.sh|documents|custom_vars|settings_*|prefix_*)

	clear; echo "Directory has been cleaned."
	exit
elif [ "$1" = "--icons" ] || [ "$1" = "--remove-icons" ]; then
	if [ ! -f "$DIR/game_info/game_info.txt" ]; then
		echo "There is no game_info.txt file!"
		exit
	fi

	# Get game information
	GAME_INFO="$(cat "$DIR/game_info/game_info.txt")"
	GAME="$(echo "$GAME_INFO" | sed -n 6p)"

	if [ "$1" = "--icons" ]; then
		# Generate desktop file
		echo "[Desktop Entry]" > "$GAME.desktop"
		echo "Version=1.0" >> "$GAME.desktop"
		echo "Name=$GAME" >> "$GAME.desktop"
		echo "Type=Application" >> "$GAME.desktop"
		echo "Exec=$DIR/start.sh" >> "$GAME.desktop"
		echo "Icon=$DIR/game_info/icon" >> "$GAME.desktop"
		echo "Categories=Game;" >> "$GAME.desktop"

		# Copy desktop file
		mkdir -p "$HOME/.local/share/applications"
		if [ -d "$HOME/Desktop" ]; then cp "$GAME.desktop" "$HOME/Desktop"; fi
		if [ -d "$HOME/Рабочий стол" ]; then cp "$GAME.desktop" "$HOME/Рабочий стол"; fi
		mv "$GAME.desktop" "$HOME/.local/share/applications"

		clear; echo "Icons created!"
	else
		# Remove desktop file
		rm -f "$HOME/Desktop/$GAME.desktop"
		rm -f "$HOME/Рабочий стол/$GAME.desktop"
		rm -f "$HOME/.local/share/applications/$GAME.desktop"

		clear; echo "Icons removed!"
	fi

	exit
fi

if [ ! -d prefix ]; then
	echo "Run start.sh first!"
	exit
fi

if [ "$1" = "--cfg" ]; then
	"$WINE" winecfg
elif [ "$1" = "--reg" ]; then
	"$WINE" regedit
elif [ "$1" = "--kill" ]; then
	"$WINESERVER" -k
elif [ "$1" = "--fm" ]; then
	"$WINE" winefile
fi
