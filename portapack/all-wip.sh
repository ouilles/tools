#!/bin/bash

# This script will:
# 1. update a Debian based OS
# 2. install the necessary ARM compiler to /opt/armbin (if not done before)
# 3. clone the eried's mayhem repository from GitHub (if not done before)
# 4. do required modification for python 3 on source
# 5. setup environmental variables for compiler
# 6. create makefile through cmake and compile
# 7. flash the firmware to HackRF!

# Update the system and install arm compiler if non-existant
if [ ! -d ./arm-gcc ]; then
	echo "--- Updating system - installing packages ---"
	sleep 1
	sudo apt-get update
	sudo apt-get install -y git tar wget dfu-util cmake python3 bzip2 curl hackrf python3-distutils python3-setuptools
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py; python3 get-pip.py
	rm get-pip.py
	pip install pyyaml

	echo "--- Updating system - installing ARM compiler ---"
	sleep 1
	mkdir ./arm-gcc; cd ./arm-gcc
	wget -O gcc-arm-none-eabi.tar.bz2 'https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2?revision=05382cca-1721-44e1-ae19-1e7c3dc96118&la=en&hash=D7C9D18FCA2DD9F894FD9F3C3DC9228498FA281A'
	# mkdir armbin
	tar --strip=1 -xjvf gcc-arm-none-eabi.tar.bz2 # -C armbin
	cd ..
fi

# Clone the GitHub repository if non-existant

if [ ! -d ./portapack-mayhem-wip ]; then
	echo "--- Cloning Mayhem Portapack repository from GitHub ---"
	sleep 1
	mkdir -p portapack-mayhem-wip
	cd ./portapack-mayhem-wip
	git clone --recurse-submodules https://github.com/ouilles/portapack-mayhem.git .
	# USER=`whoami`
	# GROUP=`id -g` 
	# chown -R $USER:$GROUP /opt/portapack-mayhem
	# If needed, replace the python version in libopencm3 to use python3. This should not be needed anymore, but left here in case...
	# sed -i 's/env python$/env python3/g' portapack-mayhem/hackrf/firmware/libopencm3/scripts/irq2nvic_h
	cd ..
fi

# Compile
cd ./portapack-mayhem-wip
mkdir build; cd build
PATH=../../arm-gcc/bin:../../arm-gcc/lib:$PATH
cmake ..
make -j 6

# Flash if compiled
if [[ -f firmware/portapack-h1_h2-mayhem.bin ]]; then
	# Flash
	clear
	echo "FIRMWARE COMPILED! WARNING: DISCONNECT DEVICE TO AVOID FLASHING."
	echo "--- Firmware was compiled! Please connect HackRF in the next 20 seconds to flash (update firmware) or press CTRL+C to cancel flashing HackRF! ---"
	sleep 20
	hackrf_spiflash -w firmware/portapack-h1_h2-mayhem.bin
fi

# additional tip: create a new branch from next 
# git checkout -b name_of_app_warning_fix origin/next
