#!/usr/bin/env bash
set -euo pipefail


BuildTarget() {
  case "$1" in
    clean)
      rm -rf ../build
      ;;
    full)
      rm -rf ../build/full
      mkdir -p ../build/full
      cp -r * ../build/full
      chmod +x ../build/full/install.sh
      (cd ../build && tar czf DrBash-full.tar.gz full/)
      rm -rf ../build/full
      echo "Full build created at ../build/DrBash-full.tar.gz"
      ;;
    lite)
      rm -rf ../build/lite
      mkdir -p ../build/lite
      cp -r * ../build/lite
      rm -rf ../build/lite/media.shd
      chmod +x ../build/lite/install.sh
      (cd ../build && tar czf DrBash-lite.tar.gz lite/)
      rm -rf ../build/lite
      echo "Lite build created at ../build/DrBash-lite.tar.gz"
      ;;
    install)
      chmod +x ./install
      ./install
      ;;
    *)
      echo "Usage: $0 [clean|all|full|lite|install]"
      exit 1
      ;;
  esac
}

if [ "${1,,}" == 'all' ]; then
  BuildTarget clean
  BuildTarget lite
  BuildTarget full
else
  BuildTarget "$1"
fi
