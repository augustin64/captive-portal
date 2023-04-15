#!/usr/bin/bash

# General config
HOTSPOT_NAME="My Secure Wifi"
DOMAIN_NAME="connect.wifi.local"
# Nginx config
NGINX_USER="http" # Nginx user, use `ps -aux | grep nginx` if you're not sure about the one used on your distro
WWW_FILES="www" # Html files to server


TEMP_DIR=$(mktemp -d)
TEMP_NGINX_CONFIG=$(mktemp)
TEMP_WWW=$(mktemp -d)

log () {
	# Comment to disable logging
  	echo [$(date)] $@
}

# Set up iptables
sudo iptables \
		-t nat \
		-A PREROUTING \
		-i wlp170s0 \
		-p tcp \
		-m tcp \
		--dport 80 \
		-j DNAT \
		--to-destination 10.42.0.1

# Create and mount temporary filesystem
log "Create & mount temporary filesystem"
rsync -a etc/NetworkManager/ "$TEMP_DIR"
grep -rl 'example.com' "$TEMP_DIR" | xargs sed -i "s/example\.com/$DOMAIN_NAME/g"
sudo mount --bind "$TEMP_DIR" /etc/NetworkManager

# Reload NetworkManager config
log "Restart NetworkManager"
sudo systemctl restart NetworkManager

# Create open hotspot
log "Start hotspot"
nmcli connection add type wifi \
			con-name "$HOTSPOT_NAME" \
			autoconnect no \
			wifi.mode ap \
			wifi.ssid "$HOTSPOT_NAME" \
			ipv4.method shared \
			ipv6.method shared

nmcli con up "$HOTSPOT_NAME"


# Set up NGINX
rsync -a "$WWW_FILES" "$TEMP_WWW"
sudo chown $NGINX_USER:$NGINX_USER -R "$TEMP_WWW"
cp etc/nginx.conf "$TEMP_NGINX_CONFIG"

sed -i "s/example\.com/$DOMAIN_NAME/g" "$TEMP_NGINX_CONFIG"
sed -i "s@PWD@$TEMP_WWW@g" "$TEMP_NGINX_CONFIG"
sudo nginx -t -q -c "$TEMP_NGINX_CONFIG"
sudo nginx -c "$TEMP_NGINX_CONFIG"

log "Server started [Ctrl-C] to quit"
( trap exit SIGINT ; read -r -d '' _ </dev/tty ) ## wait for Ctrl-C


log "Exit signal received"
# Cancel all modifications
sudo nginx -s stop # Stop nginx
sudo iptables -t nat -F # Remove iptables rules
# Remove overlayfs
sudo umount /etc/NetworkManager
sudo systemctl restart NetworkManager
# Remove temp files
sudo rm -rf "$TEMP_DIR/system-connections" 
rm -rf "$TEMP_DIR"
rm "$TEMP_NGINX_CONFIG"
sudo rm -rf "$TEMP_WWW"
log "Config cleaned !"
