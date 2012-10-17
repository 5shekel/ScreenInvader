#!/bin/bash
#
# ScreenInvader - A shared media experience. Instant and seamless.
#  Copyright (C) 2012 Amir Hassan <amir@viel-zu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

(
set -x 

[ -z "$LC_ALL" ] && export LC_ALL=C
cd `dirname $0`
chvt 2
export HOME=/root

janosh="/lounge/bin/janosh"

sudo -u lounge bash -c "cat /lounge/lounge.json | /lounge/bin/janosh -l"
cat /root/root.json | $janosh -l

if [ -f ./answer.sh ]; then
  source ./answer.sh
else
  source ./askconfig.sh
fi

function makeHostname() {
  $janosh -t -s /network/hostname "$1"
}

function makeDNS() {
  $janosh -t -s /network/nameserver "$1"
}

function makeDHCPNet() {
  $janosh -e makeNetworkDhcp -s /network/connection/interface "$1"
}

function makeManualNet() {
  $janosh -e makeNetworkMan -s /network/connection/interface "$1" /network/address "$2" /network/netmask "$3" /network/gateway "$4"
}

function makeWifi() {
  $janosh -t -s /network/connection/interface "$1" /network/wifi/ssid "$2" /network/wifi/encryption/value "$3" /network/wifi/passphrase "$4"
}

function doConf() {
	${1}Conf
}

function hostnameConf(){
  hostname=
  while [ -z "$hostname" ]; do  
    hostname=$(askHostname)
  done

  makeHostname "$hostname"
  doConf "connection"
}

INTERFACE=

function connectionConf() {
  howconf=$(askNetConnection)
  if [ $? == 0 ]; then
    $janosh -s /network/connection/value "$howconf"
    if [ "$howconf" == "Wifi" ]; then
      doConf "wireless"
    elif  [ "$howconf" == "Ethernet" ]; then
      export INTERFACE="`/root/triggers/network readWiredNics`"
      doConf "network"
    fi
  else
    doConf "hostname"
  fi
}

function wirelessConf() {
  ssid=$(askWifiSSID)
  if [ $? == 0 ]; then
    encrypt=$(askWifiEncryption)
    if [ "$encrypt" == "WPA-PSK" -o "$encrypt" == "WEP" ]; then
      passphrase=$(askWifiPassphrase)
    fi
    export INTERFACE="`/root/triggers/network readWirelessNics`"
    makeWifi "$INTERFACE" "$ssid" "$encrypt" "$passphrase"
    doConf "network"
  else
    doConf "connection"
  fi
}

function networkConf() {
  howconf=$(askHowNet)
  if [ $? == 0 ]; then
    if [ "$howconf" == "dhcp" ]; then
      makeDHCPNet "$INTERFACE"
    elif  [ "$howconf" == "manual" ]; then
      netconf=$(askManualNetwork)
      if [ $? == 0 ]; then
        set $netconf
        makeManualNet "$INTERFACE" "$1" "$2" "$3"
        makeDNS "$4"
      else
        doConf "network"
      fi
    fi
    doConf "reboot"
  else
    doConf "connection"
  fi
}

function rebootConf(){
  if askDoReboot; then
   finish
  else
   doConf "hostname"
  fi
}

function finish() {
 update-rc.d autofs defaults
 update-rc.d thttpd defaults
 update-rc.d mpd defaults
 update-rc.d xserver defaults

 mkdir -p /share
 mkdir -p /var/cache/debconf/
 mkdir -p /var/run/mpd/
 mkdir -p /var/lib/mpd
 chown -R mpd:audio  /var/lib/mpd
 chown -R mpd:audio /var/run/mpd/
 chmod a+rwx /var/run/mpd/
 chown -R lounge:lounge /lounge/

 usermod -s /bin/bash root
 $janosh -e makeDefaultInittab
 /sbin/shutdown -r now
}

doConf "hostname"
) &> /setup.log
