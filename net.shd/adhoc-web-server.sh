#!/bin/bash

python -m SimpleHTTPServer 8080 > /var/log/adhoc-web-server.log 2>&1 &
