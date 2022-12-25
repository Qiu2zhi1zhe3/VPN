#!/system/bin/sh
busybox_path="/data/adb/magisk/busybox"
VPN="/data/VPN"
Clash_bin="Clash.Meta"
Clash="${VPN}/${Clash_bin}"
SingBox_bin="SingBox"
SingBox="${VPN}/${SingBox_bin}"
magenta="\033[1;35m"
green="\033[1;32m"
white="\033[1;37m"
blue="\033[1;34m"
red="\033[1;31m"
black="\033[1;40;30m"
yellow="\033[1;33m"
cyan="\033[1;36m"
reset="\033[0m"

if [[ "$(id -u)" -ne 0 ]]; then
  echo -e "${red} Vui lòng chạy với quyền root"
  exit
fi

singbox() {
	chmod 0700 ${SingBox}
	nohup ${busybox_path} setuidgid 0:3005 ${SingBox} run -D ${VPN} >  /dev/null 2>&1 &
	sleep 2
	if [[ $(pidof ${SingBox_bin}) ]] ; then
		ip rule add from all iif tun0 lookup main suppress_prefixlength 0 pref 8000
		ip rule add lookup main pref 7000
		iptables -w 100 -I FORWARD -o tun0 -j ACCEPT
		iptables -w 100 -I FORWARD -i tun0 -j ACCEPT
		echo "Singbox đã được bắt đầu"
		sed -i 's/clash/singbox/g' /data/adb/modules/VPN/service.sh
		ps -p $(pidof ${SingBox_bin}) -o pid,uid,gid,rss,vsz,%cpu,time
	else
		 echo -e "${red} Error"
		echo $(${SingBox} check -D ${VPN})
	fi
}

clash() {
	chmod 0700 ${Clash}
	ulimit -SHn 1000000
	nohup ${busybox_path} setuidgid 0:3005 ${Clash} -d ${VPN} > /dev/null 2>&1 &
	sleep 2
	if [[ $(pidof ${Clash_bin}) ]] ; then
		mkdir -p /dev/net
		ln -sf /dev/tun /dev/net/tun
		iptables -w 100 -I FORWARD -o Meta -j ACCEPT
		iptables -w 100 -I FORWARD -i Meta -j ACCEPT
		sed -i 's/singbox/clash/g' /data/adb/modules/VPN/service.sh
		echo "Clash đã được bắt đầu"
		ps -p $(pidof ${Clash_bin}) -o pid,uid,gid,rss,vsz,%cpu,time
	else
		 echo -e "${red} Error"
	fi
}

stop() {
	if [[ $(pidof ${Clash_bin}) ]] ; then
		echo "Stop Clash , $(pidof Clash)"
		kill -15 $(pidof ${Clash_bin})
		iptables -w 100 -D FORWARD -o Meta -j ACCEPT
		iptables -w 100 -D FORWARD -i Meta -j ACCEPT
	else
		if [[ $(pidof ${SingBox_bin}) ]] ; then
			echo "Stop SingBox , $(pidof SingBox)"
			kill -15 $(pidof ${SingBox_bin})
			iptables -w 100 -D FORWARD -o tun0 -j ACCEPT
			iptables -w 100 -D FORWARD -i tun0 -j ACCEPT
			ip rule del pref 7000
			ip rule del pref 8000
		fi
    fi
}

view() {
	if [[ $(pidof ${Clash_bin}) ]] ; then
		 echo -e "${magenta}                   Clash.Meta Đang chạy"
		echo -en "${yellow}"
		ps -p $(pidof ${Clash_bin}) -o pid,uid,gid,rss,vsz,%cpu,time
	else
		if [[ $(pidof ${SingBox_bin}) ]] ; then
			 echo -e "${magenta}                SingBox Đang chạy"
			echo -en "${yellow}"
			ps -p $(pidof ${SingBox_bin}) -o pid,uid,gid,rss,vsz,%cpu,time
		fi
    fi
}
update() {
	cd /data/VPN
	mv config.yaml config.yaml.bk
	mv config.json config.json.bk
	git fetch --all && git reset --hard origin/VPN && git pull origin VPN
	mv config.yaml.bk config.yaml
	mv config.json.bk config.json
	echo -en "${green} VPN Đã Được Cập Nhật"
}
uninstall() {
	rm -rf /data/VPN /data/adb/modules/VPN
	echo -en "${green} VPN Gỡ Cài Đặt"
}
menu() {
 MENU=(      "Bắt Đầu Chạy Clash.Meta"
             "Bắt Đầu Chạy SingBox"
			 "Mở Bảng Điều Khiển"
             "Dừng VPN"
             "Trạng Thái VPN"
             "Cập Nhật"
             "Gỡ Cài Đặt"
             "Thoát Menu"
)
echo -e ""
echo -e "                     ${magenta}Qiu2zhi1zhe3 "
echo -e "              ${red} ${white}github.com/Qiu2zhi1zhe3"
echo -e "${blue}                      Menu ${red} ${blue}VPN"
echo -e ""
echo -en "${green}"
select menu in "${MENU[@]}"; do
case $REPLY in 
         1 ) clear
             stop
             sleep 2
  		   clash
  		   menu;;
         2 ) clear
             stop
             sleep 2
             singbox
             menu;;
         3 ) clear
             xdg-open http://localhost:9090/ui/#/proxies
             menu ;;
         4 ) clear
             stop
             menu ;;
         5 ) clear
         	view
             menu;;
         6 ) clear
         	update
         	menu
             ;;
         7 ) clear
         	uninstall
             exit ;;    
         8 ) clear
             exit ;;    
          *)  echo -en "${red} Vui Lòng Nhập Số Trong Menu "
			 sleep 2 
			 clear
			 menu ;;
    esac
done

}

case "$1" in
  clash)
  	stop
  	sleep 2
  	clash
  	;;
  singbox)
  	stop
  	sleep 2
  	singbox
  	;;	
  stop)
    stop
    ;;
  web)
    xdg-open http://localhost:9090/ui/#/proxies 
    ;;
  view)
    view 
    ;;  
  *)clear
    menu
    ;;
esac
