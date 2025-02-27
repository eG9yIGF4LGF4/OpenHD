#!/usr/bin/env bash
set -e

PLATFORM="$1"


BASE_PACKAGES="libusb-1.0-0-dev libpcap-dev libsodium-dev libnl-3-dev libnl-genl-3-dev libnl-route-3-dev libsdl2-dev"
VIDEO_PACKAGES="libgstreamer-plugins-base1.0-dev libv4l-dev"
CORAL_PACKAGES="libedgetpu-dev libedgetpu1-std"
BUILD_PACKAGES="git build-essential autotools-dev automake libtool python3-pip autoconf apt-transport-https ruby-dev cmake libpython3-dev libusb-1.0-0-dev"


function install_pi_packages {
PLATFORM_PACKAGES="libcamera-openhd"
PLATFORM_PACKAGES_REMOVE="python3-libcamera libcamera0"
}
function install_x86_packages {
PLATFORM_PACKAGES="libunwind-dev gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly"
PLATFORM_PACKAGES_REMOVE=""
}
function install_rock_packages {
PLATFORM_PACKAGES="gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly"
PLATFORM_PACKAGES_REMOVE=""
}

 # Add OpenHD Repository platform-specific packages
 apt install -y curl
 curl -1sLf 'https://dl.cloudsmith.io/public/openhd/release/setup.deb.sh'| sudo -E bash

 PKG_LIST="/etc/apt/sources.list.d/openhd-release.list"

 rm /etc/apt/sources.list.d/openhd*
 touch $PKG_LIST
 
 echo "deb https://dl.cloudsmith.io/public/openhd/release/deb/raspbian bullseye main" | tee -a $PKG_LIST
 echo "deb https://dl.cloudsmith.io/public/openhd/dev-release/deb/raspbian bullseye main" | tee -a $PKG_LIST
 echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee -a $PKG_LIST

 wget -O - -q "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add -
 wget -O - -q "https://dl.cloudsmith.io/public/openhd/release/gpg.556700D37C2BB5E8.key" | apt-key add -
 wget -O - -q "https://dl.cloudsmith.io/public/openhd/dev-release/gpg.C3F2B13772CD7F9E.key" | apt-key add -
        
 apt update
 apt upgrade -y --allow-downgrades

# Main function
 
 if [[ "${PLATFORM}" == "rpi" ]]; then
    install_pi_packages
 elif [[ "${PLATFORM}" == "ubuntu-x86" ]] ; then
    install_x86_packages
 elif [[ "${PLATFORM}" == "rock5" ]] ; then
    install_rock_packages
 else
    echo "platform not supported"
 fi


 # Install platform-specific packages
 echo "Removing platform-specific packages..."
 for package in ${PLATFORM_PACKAGES_REMOVE}; do
     echo "Removing ${package}..."
     apt purge -y ${package}
     if [ $? -ne 0 ]; then
         echo "Failed to remove ${package}!"
         exit 1
     fi
 done

 # Install platform-specific packages
 echo "Installing platform-specific packages..."
 for package in ${PLATFORM_PACKAGES} ${BASE_PACKAGES} ${VIDEO_PACKAGES} ${CORAL_PACKAGES} ${BUILD_PACKAGES}; do
     echo "Installing ${package}..."
     apt install -y -o Dpkg::Options::="--force-overwrite" --no-install-recommends ${package}
     if [ $? -ne 0 ]; then
         echo "Failed to install ${package}!"
         exit 1
     fi
 done

# Installing ruby packages
gem install fpm

# libcoral compile and install
#git clone --recurse-submodules https://github.com/google-coral/libcoral
#cd libcoral
#make CPU=armv7a  
#make CPU=armv7a 
#make CPU=armv7a install
