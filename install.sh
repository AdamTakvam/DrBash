#!/bin/bash

 
if [ -d full ]; then # Full installation
  echo "Installing Dr. Bash (Full)..."
  
  echo -n "Where is your media repository located? "
  read USERMEDIA
 
  USERLIB="/usr/local/lib/DrBash"
  USERSRC="/usr/local/src/DrBash"
  USERENV="/usr/local/env/DrBash"
  USERBIN="$HOME/bin"
  USERDATA="$HOME/DrBash/config"

  for dir in "$USERLIB" "$USERSRC" "$USERENV" "$USERBIN" "$USERDATA"; do 
    sudo mkdir -p "$dir"
    sudo chown -R $(whoami):users "$dir"
    find . -type d -exec sudo chmod 775 '{}' \;
  done

  cd full; 
  sudo cp -r lib/* "$USERLIB"
  sudo cp -r env/* "$USERENV"
  sudo cp -r *.shd "$USERSRC" 2>/dev/null || true
  sudo cp * "$USERSRC"

  "$USERSRC/mkbinlink"

  echo "We're done here, but you're not quite done yet."
  echo "Regarding the media scripts specifically, you've still got some configuring to do."
  echo "See the README.md file for all of the details about the configuration files you can configure in $USERDATA."
  echo
  echo "Additionally, you're going to want to add the following lines anywhere you want in your ~/.bashrc file:"
  echo -e "\tUSERLIB=$USERLIB"
  echo -e "\tUSERSRC=$USERSRC"
  echo -e "\tUSERENV=$USERENV"
  echo -e "\tUSERBIN=$USERBIN"
  echo -e "\tUSERDATA=$USERDATA"
  echo -e "\tUSERMEEDIA=$USERMEDIA"
  echo
  echo "Lastly, run "source ~/.bashrc" (without quotes) to reinitialize your environment and complete the installation process."
else # Minimal installation
  echo "Installing Dr. Bash (Lite)..."

  USERLIB="/usr/local/lib/DrBash"
  USERSRC="/usr/local/src/DrBash"
  USERENV="/usr/local/env/DrBash"
  USERBIN="$HOME/bin"

  for dir in "$USERLIB" "$USERSRC" "$USERENV" "$USERBIN"; do 
    sudo mkdir -p "$dir"
    sudo chown -R $(whoami):users "$dir"
    find . -type d -exec sudo chmod 775 '{}' \;
  done

  cd lite; 
  sudo mv -r lib/* "$USERLIB"
  sudo mv -r env/* "$USERENV"
  sudo mv -r *.shd "$USERSRC"
  sudo mv * "$USERSRC"

  "$USERSRC/mkbinlink"

  echo "We're done here, but you're not quite done yet."
  echo "You're going to want to add the following lines anywhere you want in your ~/.bashrc file:"
  echo -e "\tUSERLIB=$USERLIB"
  echo -e "\tUSERSRC=$USERSRC"
  echo -e "\tUSERENV=$USERENV"
  echo -e "\tUSERBIN=$USERBIN"
  echo -e "\tUSERDATA=$USERDATA"
  echo
  echo "Lastly, run "source ~/.bashrc" (without quotes) to reinitialize your environment and complete the installation process."
fi
