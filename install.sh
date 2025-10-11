#!/bin/bash

Help() {
  tabs 4
  echo "Dr. Bash v0.7 installation utility"
  echo
  echo "Usage: ./install [edition]"
  echo
  echo "edition"
  echo -e "\tfull\tFull installation (includes all optional modules) [Default]"
  echo -e "\ylite\tIncludes only the core libraries and some standard utilities."
  echo
  echo "Which edition should I choose?"
  echo "The general guidance is that users should install the full edition and people wanting to write their own modules using Dr. Bash as a development platform only need a lite install."
  echo "But, pragmatically, where things sit right now, it's all about whether or not you want the media library module. If your situation is anything other than a Linux server hosting videos to client workstations (ideally running Windows for full feature compatability) then you might as well just go with the lite edition because the media module is huge and complex and will get in your way if you don't want it. For example, if you perform a full install right now, the very first prompt will ask for the location of your media repository. If you don't have one, this question might be distressing. But we don't want to distress you. So if you just press <enter> when you see that question, we quietly switch you to the lite install because we're helpful like that."
  echo
  echo "Media Module FAQ:"
  echo "1. I have movies on my server, but they are sorted by genre or year or whatever, so do I just point to the root directory of that structure?"
  echo "Answer: Sadly, no. The media module assumes that no organization has been done with your video collection and you want it to organize things for you. The state of the module currently is that it will make a vast repository of movies in a single directory very navigable so you can easily create genre listings on the fly without the need for moving them into subdirectories. But later releases will include options to create actual hierarchies for compatability with other media tools."
  echo 
  echo "2. Will the media module help me to manage my collection of audio files or is it only for videos?"
  echo "Answer: There is nothing about the media module that limits it to only working with videos (that we know of). But it's written for video collections. So the question isn't whether it will curate your audio files, but whether it will do so in the way you want or expect."
  echo
  echo "3. I have a directory full of videos for ya, but it's HUGE! I'm talking about easily over 1,000 videos in the one directory alone. Are you sure this video module is up to the challenge?"
  echo "Answer: *yawn* The test dataset we use to develop the media module contains over 10,000 videos and we can list every one containing any actor you choose in button-press time."
  echo
  echo "4. Is there a client-side UI? How does the workstation user interact with the media module?"
  echo "Answer: It's called Dr. Bash for a reason. You interact with it via SSH and run the bash scripts described in the manpage. Just type: 'man drbash' and scroll to the Media Module section. It'll explain all of the commands and how they are used. But the main way that the barrier is crossed between client and server beyond just information you can read is by using the 'findvideo' command (which is really the heart of the whole thing) to create a playlist out of your search results that can then be played on Windows Media Player (new or classic), VLC, and probably others. That being said, there's nothing preventing a GUI client from being constructed for it. But that's out of scope for what started out as a demo of a bash scripting platform."
  echo
  echo "5. I'm running Plex Media Server, do I need the media module?"
  echo "Answer: If Plex is providing you with all of the functionality you require, then I'd have to say that you don't. If you find that it's ability to tag and sort videos is woefully inadequate for your needs and you're willing to give up the snazzy web interface (for now), then you might want to give the media module a try."
  echo
  echo "6. I'd like to try the media module, but I'm nervous that a bug might delete all my files. Are you sure it's safe?"
  echo "Answer: Am I sure it's safe? No. But I'll say that in the 5 years it's been developed, there hasn't been any unintentional media-deleting incidents. But that doesn't mean that there couldn't be. The media module does include a utility (setperms) specifically for the paranoid that tightly manages file permissions so that the main repository is read-only to the user except in special circumstances where sudo is used to gain write permissions only when absolutely necessary. That doesn't eliminate the possibility of catastrophe, and you should always have backups of any critical data, but it drastically reduces the possibility."
}

DoInstallCommon() {
  DRB_LIB="/usr/local/lib/"
  DRB_SRC="/usr/local/src/"
  DRB_ENV="/usr/local/env/"
  DRB_BIN="/usr/local/bin"
  DRB_DATA="$HOME/.DrBash"

  for dir in "$DRB_LIB" "$DRB_SRC" "$DRB_ENV" "$DRB_BIN" "$DRB_DATA"; do 
    sudo mkdir -p "$dir"
    sudo chown -R $(whoami):users "$dir"
    find . -type d -exec sudo chmod 775 '{}' \;
  done
}

InstallCorrupted() {
  echo "Error: The installation source is corrupt. We're sorry. We screwed up. Check our GitHub for a new edition soon!"
  exit 1
}

ShowSalutation() {
  declare -a setvars
  setvars+=("DRB_LIB=\"$DRB_LIB\"")
  setvars+=("DRB_SRC=\"$DRB_SRC\"")
  setvars+=("DRB_ENV=\"$DRB_ENV\"")
  setvars+=("DRB_BIN=\"$DRB_BIN\"")
  setvars+=("DRB_DATA=\"$DRB_DATA\"")
  [[ "$edition" == full ]] && setvars+=("DRB_MEDIA=\"$DRB_MEDIA\"")

  printf "%b\n" "We're done here, but you're not quite done yet."
  if [[ "$edition" == full ]]; then
    printf "%b\n" "Regarding the media scripts specifically, you've still got some configuring to do."
    printf "%b\n" "See the README.md file for all of the details about the configuration settings you can monkey with using drbashctl."
  fi
  echo
  printf "%b\n" "Additionally, you're going to want to add the following lines anywhere you want in your ~/.bashrc file:"
  printf "\t%b\n" "${setvars[@]}"
  echo
  printf "%b\n" "Lastly, run \"source ~/.bashrc\" (without quotes) to reinitialize your environment and complete the installation process."
  echo
  printf "%b\n" "We don't edit people's startup files automatically because a lot of folks are picky about how their shit is set up."
  echo
  read -n1 "But would you like us to just cram those lines in just any old place as long as it works (y/N)? " choice
  if [[ "${choice,,}" == 'y' ]]; then
    printf "%b\n" "${setvars[@]}" >> ~/.bashrc
    printf "%b\n" "We told you it wouldn't hurt! You let us stuff those lines right up your boot file like pro! We're proud of you!"
    printf "%b\n" "However, there is still one last thing we cannot do, and that is to reload that file into your environment."
    printf "%b\n" "So you either need to run: source ~/.bashrc or log out and log back in. Then you can play with all of our dangly bits!"
  else
    printf "%b\n" "We don't blame you. We're liable to shove things just any old place. It could get awkward!"
  fi
}

InstallManpages() {
  local MAN_REPO="/usr/local/share/man/man1"
  sudo mkdir -p "$MAN_REPO"
  sudo mv *.gz "$MAN_REPO"
  sudo mandb 1>/dev/null
}

VerifyInstallerIntegrity() {
  case "$edition" in
    full) 
      [[ -d full ]] || InstallCorrupted ;;
    lite) 
      [[ -d lite ]] || InstallCorrupted ;;
    *)
      Help
      exit 1 ;;
  esac
}

FullInstall() {
  [[ "$edition" == "Full" ]] && return 0 || return 1
}

DoInstall() {

  printf "%b\n" "Installing Dr. Bash ($edition)..."
  
  if FullInstall; then
    
    read -p "Where is your media repository located? " DRB_MEDIA
    
    if [[ -z "$DRB_MEDIA" ]]; then
      printf "%b\n" "No media repo? No problem. We'll just switch you to the lite install..."
      edition="Lite"
      pause
      read "Are feeling confused and getting panicky right now, afraid that you've made a mistake? (Y/n)? " mistake
      if [[ "${mistake,,}" == 'y' ]]; then
        printf "%b\n" "Yeah, we thought so. We're just going to let you out of the installer without any harm done."
        printf "%b\n" "The next thing you want to do is run: ./install -h"
        printf "%b\n" "That should thoroughly explain what's going on so that you can complete this installation confidently."
        exit 1
      fi
    fi
  fi

  DoInstallCommon

  FullInstall && cd full || cd lite 
  sudo cp -r lib/* "$DRB_LIB"
  sudo cp -r env/* "$DRB_ENV"
  sudo cp -r *.shd "$DRB_SRC" 2>/dev/null || true
  sudo cp * "$DRB_SRC"

  "$DRB_SRC/mkbinlink"

  InstallManpages

  ShowSalutation
}

declare -g edition
[[ "${1,,}" == full ]] && edition="Full" || edition="Lite"

VerifyInstallerIntegrity

DoInstall
