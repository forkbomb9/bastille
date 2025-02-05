#!/bin/sh
#
# Copyright (c) 2018-2021, Christer Edwards <christer.edwards@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

. /usr/local/share/bastille/common.sh
. /usr/local/etc/bastille/bastille.conf

usage() {
    error_exit "Usage: bastille list [-j|-a] [release|template|(jail|container)|log|limit|(import|export|backup)]"
}

if [ $# -eq 0 ]; then
   /usr/sbin/jls -N
fi

if [ "$1" == "-j" ]; then
    /usr/sbin/jls -N --libxo json
    exit 0
fi

if [ $# -gt 0 ]; then
    # Handle special-case commands first.
    case "$1" in
    help|-h|--help)
        usage
        ;;
    all|-a|--all)
        if [ -d "${bastille_jailsdir}" ]; then
            DEFAULT_VALUE="-"
            SPACER=2
            MAX_LENGTH_JAIL_NAME=$(find "${bastille_jailsdir}" -maxdepth 2 -type f -name jail.conf | sed "s/^.*\/\(.*\)\/jail.conf$/\1/" | awk '{ print length($0) }' | sort -nr | head -n 1)
            MAX_LENGTH_JAIL_NAME=${MAX_LENGTH_JAIL_NAME:-3}
            if [ ${MAX_LENGTH_JAIL_NAME} -lt 3 ]; then MAX_LENGTH_JAIL_NAME=3; fi
            MAX_LENGTH_JAIL_IP=$(find "${bastille_jailsdir}" -maxdepth 2 -type f -name jail.conf -exec sed -n "s/^[ ]*ip[4,6].addr[ ]*=[ ]*\(.*\);$/\1/p" {} \; | sed 's/\// /g' | awk '{ print length($1) }' | sort -nr | head -n 1)
            MAX_LENGTH_JAIL_IP=${MAX_LENGTH_JAIL_IP:-10}
            MAX_LENGTH_JAIL_VNET_IP=$(find "${bastille_jailsdir}" -maxdepth 2 -type f -name jail.conf -exec grep -l "vnet;" {} + | sed 's/\(.*\)jail.conf$/grep "ifconfig_vnet0=" \1root\/etc\/rc.conf/' | sh | sed -n 's/^ifconfig_vnet0="\(.*\)"$/\1/p' | sed 's/\// /g' | awk '{ if ($1 ~ /^[inet|inet6]/) print length($2); else print 15 }' | sort -nr | head -n 1)
            MAX_LENGTH_JAIL_VNET_IP=${MAX_LENGTH_JAIL_VNET_IP:-10}
            if [ ${MAX_LENGTH_JAIL_VNET_IP} -gt ${MAX_LENGTH_JAIL_IP} ]; then MAX_LENGTH_JAIL_IP=${MAX_LENGTH_JAIL_VNET_IP}; fi
            if [ ${MAX_LENGTH_JAIL_IP} -lt 10 ]; then MAX_LENGTH_JAIL_IP=10; fi
            MAX_LENGTH_JAIL_HOSTNAME=$(find "${bastille_jailsdir}" -maxdepth 2 -type f -name jail.conf -exec sed -n "s/^[ ]*host.hostname[ ]*=[ ]*\(.*\);$/\1/p" {} \; | awk '{ print length($0) }' | sort -nr | head -n 1)
            MAX_LENGTH_JAIL_HOSTNAME=${MAX_LENGTH_JAIL_HOSTNAME:-8}
            if [ ${MAX_LENGTH_JAIL_HOSTNAME} -lt 8 ]; then MAX_LENGTH_JAIL_HOSTNAME=8; fi
            MAX_LENGTH_JAIL_PORTS=$(find "${bastille_jailsdir}" -maxdepth 2 -type f -name rdr.conf -exec awk '{ lines++; chars += length($0)} END { chars += lines - 1; print chars }' {} \; | sort -nr | head -n 1)
            MAX_LENGTH_JAIL_PORTS=${MAX_LENGTH_JAIL_PORTS:-15}
            if [ ${MAX_LENGTH_JAIL_PORTS} -lt 15 ]; then MAX_LENGTH_JAIL_PORTS=15; fi
            if [ ${MAX_LENGTH_JAIL_PORTS} -gt 30 ]; then MAX_LENGTH_JAIL_PORTS=30; fi
            MAX_LENGTH_JAIL_RELEASE=$(find "${bastille_jailsdir}" -maxdepth 2 -type f -name fstab 2> /dev/null -exec grep "/releases/.*/root/.bastille nullfs" {} \; | sed -n "s/^\(.*\) \/.*$/grep \"\^USERLAND_VERSION=\" \1\/bin\/freebsd-version 2\> \/dev\/null/p" | awk '!_[$0]++' | sh | sed -n "s/^USERLAND_VERSION=\"\(.*\)\"$/\1/p" | awk '{ print length($0) }' | sort -nr | head -n 1)
            MAX_LENGTH_JAIL_RELEASE=${MAX_LENGTH_JAIL_RELEASE:-7}
            MAX_LENGTH_THICK_JAIL_RELEASE=$(find ""${bastille_jailsdir}/*/root/bin"" -maxdepth 1 -type f -name freebsd-version 2> /dev/null -exec grep "^USERLAND_VERSION=" {} \; | sed -n "s/^USERLAND_VERSION=\"\(.*\)\"$/\1/p" | awk '{ print length($0) }' | sort -nr | head -n 1)
            MAX_LENGTH_THICK_JAIL_RELEASE=${MAX_LENGTH_THICK_JAIL_RELEASE:-7}
            if [ ${MAX_LENGTH_THICK_JAIL_RELEASE} -gt ${MAX_LENGTH_JAIL_RELEASE} ]; then MAX_LENGTH_JAIL_RELEASE=${MAX_LENGTH_THICK_JAIL_RELEASE}; fi
            if [ ${MAX_LENGTH_JAIL_RELEASE} -lt 7 ]; then MAX_LENGTH_JAIL_RELEASE=7; fi
            printf " JID%*sState%*sIP Address%*sPublished Ports%*sHostname%*sRelease%*sPath\n" "$((${MAX_LENGTH_JAIL_NAME} + ${SPACER} - 3))" "" "$((${SPACER}))" "" "$((${MAX_LENGTH_JAIL_IP} + ${SPACER} - 10))" "" "$((${MAX_LENGTH_JAIL_PORTS} + ${SPACER} - 15))" "" "$((${MAX_LENGTH_JAIL_HOSTNAME} + ${SPACER} - 8))" "" "$((${MAX_LENGTH_JAIL_RELEASE} + ${SPACER} - 7))" ""
            JAIL_LIST=$(ls "${bastille_jailsdir}" | sed "s/\n//g")
            for _JAIL in ${JAIL_LIST}; do
                if [ -f "${bastille_jailsdir}/${_JAIL}/jail.conf" ]; then
                        if [ "$(/usr/sbin/jls name | awk "/^${_JAIL}$/")" ]; then
                                JAIL_STATE="Up"
                                if [ "$(awk '$1 == "vnet;" { print $1 }' "${bastille_jailsdir}/${_JAIL}/jail.conf")" ]; then
                                        JAIL_IP=$(jexec -l ${_JAIL} ifconfig -n vnet0 inet 2> /dev/null | sed -n "/.inet /{s///;s/ .*//;p;}")
                                        if [ ! ${JAIL_IP} ]; then JAIL_IP=$(jexec -l ${_JAIL} ifconfig -n vnet0 inet6 2> /dev/null | awk '/inet6 / && (!/fe80::/ || !/%vnet0/)' | sed -n "/.inet6 /{s///;s/ .*//;p;}"); fi
                                else
                                        JAIL_IP=$(/usr/sbin/jls -j ${_JAIL} ip4.addr 2> /dev/null)
                                        if [ ${JAIL_IP} = "-" ]; then JAIL_IP=$(/usr/sbin/jls -j ${_JAIL} ip6.addr 2> /dev/null); fi
                                fi
                                JAIL_HOSTNAME=$(/usr/sbin/jls -j ${_JAIL} host.hostname 2> /dev/null)
                                JAIL_PORTS=$(pfctl -a "rdr/${_JAIL}" -Psn 2> /dev/null | awk '{ printf "%s/%s:%s"",",$7,$14,$18 }' | sed "s/,$//")
                                JAIL_PATH=$(/usr/sbin/jls -j ${_JAIL} path 2> /dev/null)
                                JAIL_RELEASE=$(jexec -l ${_JAIL} freebsd-version -u 2> /dev/null)
                        else
                                JAIL_STATE=$(if [ "$(sed -n "/^${_JAIL} {$/,/^}$/p" "${bastille_jailsdir}/${_JAIL}/jail.conf" | awk '$0 ~ /^'${_JAIL}' \{|\}/ { printf "%s",$0 }')" == "${_JAIL} {}" ]; then echo "Down"; else echo "n/a"; fi)
                                if [ "$(awk '$1 == "vnet;" { print $1 }' "${bastille_jailsdir}/${_JAIL}/jail.conf")" ]; then
                                        JAIL_IP=$(sed -n 's/^ifconfig_vnet0="\(.*\)"$/\1/p' "${bastille_jailsdir}/${_JAIL}/root/etc/rc.conf" | sed "s/\// /g" | awk '{ if ($1 ~ /^[inet|inet6]/) print $2; else print $1 }')
                                else
                                        JAIL_IP=$(sed -n "s/^[ ]*ip[4,6].addr[ ]*=[ ]*\(.*\);$/\1/p" "${bastille_jailsdir}/${_JAIL}/jail.conf" | sed "s/\// /g" | awk '{ print $1 }')
                                fi
                                JAIL_HOSTNAME=$(sed -n "s/^[ ]*host.hostname[ ]*=[ ]*\(.*\);$/\1/p" "${bastille_jailsdir}/${_JAIL}/jail.conf")
                                if [ -f "${bastille_jailsdir}/${_JAIL}/rdr.conf" ]; then JAIL_PORTS=$(awk '$1 ~ /^[tcp|udp]/ { printf "%s/%s:%s,",$1,$2,$3 }' "${bastille_jailsdir}/${_JAIL}/rdr.conf" | sed "s/,$//"); else JAIL_PORTS=""; fi
                                JAIL_PATH=$(sed -n "s/^[ ]*path[ ]*=[ ]*\(.*\);$/\1/p" "${bastille_jailsdir}/${_JAIL}/jail.conf")
                                if [ ${JAIL_PATH} ]; then
                                        if [ -f "${JAIL_PATH}/bin/freebsd-version" ]; then
                                                JAIL_RELEASE=$(sed -n "s/^USERLAND_VERSION=\"\(.*\)\"$/\1/p" "${JAIL_PATH}/bin/freebsd-version")
                                        else
                                                JAIL_RELEASE=$(grep "/releases/.*/root/.bastille nullfs" "${bastille_jailsdir}/${_JAIL}/fstab" 2> /dev/null | sed -n "s/^\(.*\) \/.*$/grep \"\^USERLAND_VERSION=\" \1\/bin\/freebsd-version 2\> \/dev\/null/p" | awk '!_[$0]++' | sh | sed -n "s/^USERLAND_VERSION=\"\(.*\)\"$/\1/p")
                                        fi
                                else
                                        JAIL_RELEASE=""
                                fi
                        fi
                        if [ ${#JAIL_PORTS} -gt ${MAX_LENGTH_JAIL_PORTS} ]; then JAIL_PORTS="$(echo ${JAIL_PORTS} | cut -c-$((${MAX_LENGTH_JAIL_PORTS} - 3)))..."; fi
                        JAIL_NAME=${JAIL_NAME:-${DEFAULT_VALUE}}
                        JAIL_STATE=${JAIL_STATE:-${DEFAULT_VALUE}}
                        JAIL_IP=${JAIL_IP:-${DEFAULT_VALUE}}
                        JAIL_PORTS=${JAIL_PORTS:-${DEFAULT_VALUE}}
                        JAIL_HOSTNAME=${JAIL_HOSTNAME:-${DEFAULT_VALUE}}
                        JAIL_RELEASE=${JAIL_RELEASE:-${DEFAULT_VALUE}}
                        JAIL_PATH=${JAIL_PATH:-${DEFAULT_VALUE}}
                        printf " ${_JAIL}%*s${JAIL_STATE}%*s${JAIL_IP}%*s${JAIL_PORTS}%*s${JAIL_HOSTNAME}%*s${JAIL_RELEASE}%*s${JAIL_PATH}\n" "$((${MAX_LENGTH_JAIL_NAME} - ${#_JAIL} + ${SPACER}))" "" "$((5 - ${#JAIL_STATE} + ${SPACER}))" "" "$((${MAX_LENGTH_JAIL_IP} - ${#JAIL_IP} + ${SPACER}))" "" "$((${MAX_LENGTH_JAIL_PORTS} - ${#JAIL_PORTS} + ${SPACER}))" "" "$((${MAX_LENGTH_JAIL_HOSTNAME} - ${#JAIL_HOSTNAME} + ${SPACER}))" "" "$((${MAX_LENGTH_JAIL_RELEASE} - ${#JAIL_RELEASE} + ${SPACER}))" ""
                fi
            done
        else
            error_exit "unfortunately there are no jails here (${bastille_jailsdir})"
        fi
        ;;
    release|releases)
        if [ -d "${bastille_releasesdir}" ]; then
            REL_LIST=$(ls "${bastille_releasesdir}" | sed "s/\n//g")
            for _REL in ${REL_LIST}; do
                if [ -f "${bastille_releasesdir}/${_REL}/root/.profile" ]; then
                    echo "${_REL}"
                fi
            done
        fi
        ;;
    template|templates)
        find "${bastille_templatesdir}" -type d -maxdepth 2
        ;;
    jail|jails|container|containers)
        if [ -d "${bastille_jailsdir}" ]; then
            JAIL_LIST=$(ls "${bastille_jailsdir}" | sed "s/\n//g")
            for _JAIL in ${JAIL_LIST}; do
                if [ -f "${bastille_jailsdir}/${_JAIL}/jail.conf" ]; then
                    echo "${_JAIL}"
                fi
            done
        fi
        ;;
    log|logs)
        find "${bastille_logsdir}" -type f -maxdepth 1
        ;;
    limit|limits)
        rctl -h jail:
        ;;
    import|imports|export|exports|backup|backups)
        ls "${bastille_backupsdir}" | grep -v ".sha256$"
    exit 0
    ;;
    *)
        usage
        ;;
    esac
fi
