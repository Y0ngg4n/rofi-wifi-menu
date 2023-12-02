#!/usr/bin/env bash

dir="$HOME/.config/rofi/launchers/type-1"
theme="${dir}/style-6.rasi"
notify-send "Getting list of available Wi-Fi networks..."
# Get a list of available wifi connections and morph it into a nice-looking list
wifi_list=$(nmcli --fields "IN-USE,SECURITY,SSID,RATE,BARS" device wifi list | sed 1d | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d" | sed 's/\*\s*/ /g' | sed 's/^\s*/  /g' | sed 's/^\s*//g')

connected=$(nmcli -fields WIFI g | tail -n 1 | xargs echo -n )
echo "$connected" > test
if [[ "$connected" == "aktiviert" ]]; then
	toggle="󰖪 Wi-Fi deaktivieren"
elif [[ "$connected" == "deaktiviert" ]]; then
	toggle="󰖩 Wi-Fi aktivieren"
fi

# Use rofi to select wifi network
chosen_network=$(echo -e "$toggle\n$wifi_list" | uniq -u | rofi -dmenu -theme "$theme" -i -selected-row 1 -p "Wi-Fi SSID: ")
# Get name of connection
read -r chosen_id <<< $(echo ${chosen_network} | sed -E 's/(^.*\s*)|(^.*\s*)|(\s*[[:digit:]]*\s\w*\/s.*)//g')
if [ "$chosen_network" = "" ]; then
	exit
elif [ "$chosen_network" = "󰖩 Wi-Fi aktivieren" ]; then
	nmcli radio wifi on
elif [ "$chosen_network" = "󰖪 Wi-Fi deaktivieren" ]; then
	nmcli radio wifi off
else
	# Message to show when connection is activated successfully
  	success_message="You are now connected to the Wi-Fi network \"$chosen_id\"."
	# Get saved connections
	saved_connections=$(nmcli -g NAME connection)
	if [[ $(echo "$saved_connections" | grep -w "$chosen_id") = "$chosen_id" ]]; then
		nmcli connection up id "$chosen_id" | grep "successfully" && notify-send "Connection Established" "$success_message"
	else
		if [[ "$chosen_network" =~ "" ]]; then
			wifi_password=$(rofi -dmenu -theme "$theme" -p "Password: " )
		fi
		nmcli device wifi connect "$chosen_id" password "$wifi_password" | grep "successfully" && notify-send "Connection Established" "$success_message"
    fi
fi
