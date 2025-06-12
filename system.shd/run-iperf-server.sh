#!/bin/bash

# Install the utility
if [ ! "$(which iperf)" ]; then
  echo "Installing the iPerf3 utility..."
  sudo apt-get update
  sudo apt-get install -y iperf
fi

# Create iperf user
[ ! "$(cat /etc/passwd | grep iperf)" ] && sudo adduser iperf --disabled-login --gecos iperf

iperf_unit_file="/etc/systemd/system/iperf3-server@.service"
if [ ! -f "$iperf_unit_file" ]; then
  sudo bash -c 'echo "[Unit] \
Description=iperf3 server on port %i \
After=syslog.target network.target \
\
[Service] \
ExecStart=/usr/bin/iperf3 -s -1 -p %i \
Restart=always \
RuntimeMaxSec=3600 \
User=iperf \
\
[Install] \
WantedBy=multi-user.target \
DefaultInstance=5201" > "$iperf_unit_file"'

  # Make SystemD reload its service configuration
  sudo systemctl daemon-reload
fi

# Activate iPerf3 server on all of its ports
for port in {9200..9240}; do
  sudo systemctl enable iperf3-server@${port}
  sudo systemctl start iperf3-server@${port}
done

showlog iperf
