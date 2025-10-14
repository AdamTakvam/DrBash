#!/bin/bash

source ./dotnet.env.sh

version="${1:-8.0}"

# install .NET SDK under ~/.dotnet
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -c "$version" -i "$HOME/.dotnet"

# now install the tool
dotnet tool install -g dotnet-script
