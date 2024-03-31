#!/bin/bash

CUSTOM="${1}"
PACKAGE_ARCH="${2}"
OS="${3}"
SLUG="${4}"

PKGDIR="/tmp/openhd-installdir"
VERSION="2.5.0-user-$(date '+%Y%m%d%H%M')-$(git rev-parse --short HEAD)"

create_package_directory() {
  rm -rf /tmp/openhd-installdir
  mkdir -p /tmp/openhd-installdir/usr/local/bin
  mkdir -p /tmp/openhd-installdir/tmp
  #Nobody should create a topdir for such things like settings, but for now it'll stay
  mkdir -p /tmp/openhd-installdir/settings
  mkdir -p /tmp/openhd-installdir/etc/systemd/system

  # We do not copy the openhd service for x86, since there we have launcher on the desktop
  # (Otherwise, we always copy it)
  if [[ "${PACKAGE_ARCH}" != "x86_64" ]]; then
    echo "we're not on x86"
      if [[ "${CUSTOM}" == "standard" ]]; then
      cp systemd/openhd.service /tmp/openhd-installdir/etc/systemd/system/openhd.service || exit 1
      else
      cp systemd/openhd-x20.service /tmp/openhd-installdir/etc/systemd/system/openhd.service || exit 1
      fi
    else
      mkdir -p /tmp/openhd-installdir/usr/share/applications/
      cp shortcuts/* /tmp/openhd-installdir/usr/share/applications/
      mkdir -p /tmp/openhd-installdir/usr/local/share/openhd_misc/
      cp shortcuts/OpenHD.ico /tmp/openhd-installdir/usr/local/share/openhd_misc/
      mkdir -p /tmp/openhd-installdir/etc/profile.d/
      cp desktop-truster.sh /tmp/openhd-installdir/etc/profile.d/
      sudo chmod +777 /tmp/openhd-installdir/etc/profile.d/desktop-truster.sh
  fi
  # always - copy the hardware.config file
  mkdir -p "${PKGDIR}/boot/openhd/"
  cp OpenHD/ohd_common/config/hardware.config "${PKGDIR}/boot/openhd/hardware.config" || exit 1
}

build_package() {

  if [[ "${PACKAGE_ARCH}" == "armhf" ]]; then
      DISTRO=$(uname -a | grep bullseye)
      if [[ -z $DISTRO ]]; then
        PKG_LIST="/etc/apt/sources.list.d/openhd.bullseye.list"
        touch $PKG_LIST
        echo "deb https://dl.cloudsmith.io/public/openhd/release/deb/raspbian bullseye main" | tee -a $PKG_LIST
        echo "deb https://dl.cloudsmith.io/public/openhd/dev-release/deb/raspbian bullseye main" | tee -a $PKG_LIST
     
        wget -O - -q "https://dl.cloudsmith.io/public/openhd/release/gpg.556700D37C2BB5E8.key" | apt-key add -
        wget -O - -q "https://dl.cloudsmith.io/public/openhd/dev-release/gpg.C3F2B13772CD7F9E.key" | apt-key add -
        
        apt-get -y update
      fi
  
    if [[ "${CUSTOM}" == "standard" ]]; then
      PACKAGE_NAME="openhd"
      PACKAGES="-d libcamera-openhd -d gst-openhd-plugins -d iw -d nmap -d aircrack-ng -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-plugins-ugly -d gstreamer1.0-libav -d gstreamer1.0-tools -d gstreamer1.0-alsa -d gstreamer1.0-pulseaudio"
      PLATFORM_CONFIGS=""
    else
      PACKAGE_NAME="openhd-x20"
      PACKAGES="-d iw -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-tools"
      PLATFORM_CONFIGS=""
    fi
  elif [[ "${PACKAGE_ARCH}" == "x86_64" ]]; then
    PACKAGE_NAME="openhd"
    PACKAGES="-d dkms -d qopenhd -d git -d iw -d nmap -d aircrack-ng -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-plugins-ugly -d gstreamer1.0-libav -d gstreamer1.0-tools -d gstreamer1.0-alsa -d gstreamer1.0-pulseaudio"
    PLATFORM_CONFIGS=""
  else
    PACKAGE_NAME="openhd"
    PACKAGES="-d iw -d nmap -d aircrack-ng -d i2c-tools -d libv4l-dev -d libusb-1.0-0 -d libpcap-dev -d libnl-3-dev -d libnl-genl-3-dev -d libsdl2-2.0-0 -d libsodium-dev -d gstreamer1.0-plugins-base -d gstreamer1.0-plugins-good -d gstreamer1.0-plugins-bad -d gstreamer1.0-plugins-ugly -d gstreamer1.0-libav -d gstreamer1.0-tools -d gstreamer1.0-alsa -d gstreamer1.0-pulseaudio"
    PLATFORM_CONFIGS=""
  fi

  rm "${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}-${SLUG}.deb" > /dev/null 2>&1 || true

  cmake OpenHD/
  make -j4
  cp openhd ${PKGDIR}/usr/local/bin/openhd || exit 1

  # Assuming fpm is installed and properly configured
  fpm -a "${PACKAGE_ARCH}" -s dir -t deb -n "${PACKAGE_NAME}" -v "${VERSION}" -C "${PKGDIR}" \
    ${PLATFORM_CONFIGS} \
    -p "${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}-${SLUG}.deb" \
    --after-install after-install.sh \
    --before-install before-install.sh \
    ${PACKAGES}
}

#Main Build
create_package_directory
build_package
