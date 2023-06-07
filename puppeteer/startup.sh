#!/bin/bash
set -e

echo "dns before"
cat /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "dns after"
cat /etc/resolv.conf

mkdir -p /dev/net 
mknod /dev/net/tun c 10 200 
chmod 600 /dev/net/tun

curl -sS https://2ip.io

echo "starting openvpn"


# Get a list of files with the .test extension in the test directory
files=(/pia-openvpn/*.ovpn)

# Check if there are any .test files in the directory
if [ ${#files[@]} -eq 0 ]; then
  echo "No .ovpn files found."
  exit 1
fi
random_index=$(( RANDOM % ${#files[@]} ))

random_opvn=${files[random_index]}

echo "Randomly selected file: $random_opvn"

echo "auth-user-pass '/pia-openvpn/auth-user-pass.txt'" >> $random_opvn

openvpn --config $random_opvn &

counter=0
while true; do
    # Check if the maximum wait time of 20 seconds has been reached
    if [ $counter -ge 20 ]; then
        echo "VPN connection timed out after 20 seconds."
        exit
    fi
    
    # ip addr show tun0 || echo .
    if ip addr show tun0 | grep -q "UP"; then
        echo "VPN is connected"
        break
    else
        echo "VPN is not yet connected. Retrying in 1 second."
        sleep 1
        counter=$((counter + 1))
    fi
done


# nslookup google.com

curl -sS https://2ip.io

/hola-proxy -bind-address 0.0.0.0:8080 -proxy-type peer &

echo "started proxy"

counter=0
while true; do
    # Check if the maximum wait time of 20 seconds has been reached
    if [ $counter -ge 20 ]; then
        echo "Proxy connection timed out after 20 seconds."
        exit
    fi
    if nc -z "localhost" "8080"; then
        echo "Proxy is ready"
        break
    else
        echo "Proxy is not yet ready. Retrying in 1 second."
        sleep 1
        counter=$((counter + 1))
    fi
done

curl -sS https://2ip.io

if [ ! -v RUN_COMMAND ] || [ -v PROXY ]; then
    echo "RUN_COMMAND=$RUN_COMMAND PROXY=$PROXY";
    while true; do sleep 10; done
else
    echo "RUN_COMMAND IS $RUN_COMMAND";
    mkdir -p screenshots
    bash $RUN_COMMAND
fi
