#!/usr/bin/env bash

install_systemd() {
    echo "Install /etc/systemd/system/autometric.timer"
    cat << _EOF_ > /etc/systemd/system/autometric.timer
[Unit]
Description=autometric timer.

[Timer]
OnBootSec=1min
OnCalendar=*:0/1

[Install]
WantedBy=basic.target
_EOF_
    echo "Install /etc/systemd/system/autometric.service"
    cat << _EOF_ > /etc/systemd/system/autometric.service
[Unit]
Description=autometric! set default routes metrics based on RTT.

[Service]
Type=oneshot
LogLevelMax=err
ExecStart=$(realpath $0)
_EOF_
    systemctl daemon-reload
    systemctl enable autometric.timer
    systemctl start  autometric.timer
    systemctl status  autometric.timer
}


if [ "$1" = "install" ];then
    install_systemd
else
    MAINIF=${1:-"eth0"}
fi
DEFAULT_METRIC=${2:-"1024"}
MAINIF_PREF=${3:-"300"}
PING_HOST=${4:-"1.1.1.1"}

defrouteCount=$(ip route list default | wc -l)

if [ "$defrouteCount" -gt 1 ]; then
    readarray defroutes < <(ip route list default | sed -E 's/\smetric\s[0-9]*//' | uniq -D)
    for ((i=1;i<=${#defroutes[@]};i++)); do
        ip route del {defroutes[$i]}
    done
    readarray defroutes < <(ip route list default | sed -E 's/\smetric\s[0-9]*//' | uniq)
    for i in ${!defroutes[@]}; do 
        dev=$(echo ${defroutes[$i]} | sed 's/.*dev\s\(\w*\)\s.*/\1/')
        rtt=$(sed -E -n "s/.*=\s([0-9]{1,4})\.[0-9]{1,4}\/.*/\1/p" <<< $(ping -n -I $dev -q -W 1 -c 1 $PING_HOST 2>/dev/null || echo '= 2000.0/'))
        test -z "$rtt" && rtt=2000 
        if [ "$dev" = "$MAINIF" ]; then
            metric=$(($DEFAULT_METRIC+$rtt))
        else
            metric=$(($DEFAULT_METRIC+$MAINIF_PREF+$rtt))
        fi
        ip route del ${defroutes[$i]}
        ip route replace ${defroutes[$i]} metric $metric
    done
fi