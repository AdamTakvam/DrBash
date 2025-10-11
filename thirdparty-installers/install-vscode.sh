#!/bin/bash

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/ms-repo-key.gpg

sudo install -o root -g root -m 644 /tmp/ms-repo-key.gpg /usr/share/keyrings/microsoft.gpg

cat > /etc/apt/sources.list.d/vscode.sources << EOF
### THIS FILE IS AUTOMATICALLY CONFIGURED ###
# You may comment out this entry, but any other modifications may be lost.
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
