#!/bin/bash

source "$DRB_LIB/drbash.sh"

declare -r APPNAME="fixzfs"
declare -r FIXEDKERNELSFILE="/usr/local/etc/drbash.zfsfix"
export FIXEDKERNELSFILE

Help() {
  tabs 4
  Log "Running Linux kernel version: $(uname -r)"
  Log
  Log "This tool is used in cases when rebooting the server causes all ZFS volumes (except boot) to vanish and modprobe tells you that ZFS cannot be loaded."
  Log
  LogHeader "Why does this occur?"
  Log "Without pulling any punches, if you're having this issue, it means that the Linux kernel team botched a release by mixing up the versions of header files. This caused DKMS to be built against a different version of the kernel than the one you are running and therefore cannot be loaded. Are we having fun yet?"
  Log
  LogTable "$(Header Usage:)\tJust run $APPNAME to start he repair process.
  \t$APPNAME -l lists all of the unfixed kernel versions you have installed.
  \t$APPNAME -h prints this help screen."
  Log
  LogHeader "What this tool does:"
  LogTable "\t1.\tConfirm that the problem is within the scope for this tool to fix.
  \t2.\tInstall the current kernel headers.
  \t3.\tRebuild DKMS.
  \t4.\tRebuild the kernel module to include ZFS.
  \t5.\tImport your pools.
  \t6.\tMount your ZFS volumes.
  \t7.\tMake the fix persist through reboot cycles.
  \t8.\tWe'll prompt you to reboot if changes necessitate it (it happens)."
  Log
  LogHeader "What closely related issues is this script unable to fix?"
  LogTable "\t-\tZFS/DKMS fails to load due to Secure Boot restrictions.
  \t-\tZFS/DKMS fails to load due to hardware failure."
  Log
  LogHeader "FAQ"
  LogTable "\tQ:\tI ran this script and rebooted and was right back where I started! You said that the changes would be made to persist through reboot cycles. But I see now that you're nothing more than a dirty, dirty liar!
  \tA:\tOh, stop it with all of that sexy talk! But you're absolutely right, sir, I'm in desperate need of a hard spanking! Once that's over, I'll point out that the fix actually did persist through the reboot. Then I'll pause there for an uncomfortably long persiod of time while you just stare at me slack-jawed. After applying some powder to my sore bottom, I explain that the script successfully repaired the version of the kernel you were running $(PrintLastFixedKernel). But you rebooted to version $(uname -r) where the problem evidently still exists (!!) and the fix hasn't been applied yet."
}

SaveFixedKernel() {
  local kernel="${1:-$(uname -r)}"
  # If we can write to the file, then add the current kernel version to the list
  if [[ -w "$FIXEDKERNELSFILE" ]]; then         
    echo "$kernel" >> "$FIXEDKERNELSFILE"
  # If it exists, but we can't write to it, change that shit
  elif [[ -f "$FIXEDKERNELSFILE" ]]; then       
    sudo chown "$(whoami)":users "$FIXEDKERNELSFILE"
    sudo chmod 664 "$FIXEDKERNELSFILE"          
    echo "$kernel" >> "$FIXEDKERNELSFILE"
  # If it doesn't exist, create it
  else        
    sudo touch "$FIXEDKERNELSFILE" 
    sudo chown "$(whoami)":users "$FIXEDKERNELSFILE"
    sudo chmod 664 "$FIXEDKERNELSFILE"          
    echo "$kernel" > "$FIXEDKERNELSFILE"
  fi
}

PrintAllFixedKernels() {
  if [[ -r "$FIXEDKERNELSFILE" ]]; then
    cat "$FIXEDKERNELSFILE" | sort -nu
  fi
}

PrintLastFixedKernel() {
  # If the file exists, print the last line
  if [[ -r "$FIXEDKERNELSFILE" ]]; then
    tail -1 "$FIXEDKERNELSFILE"
  fi
}

PrintAllUnfixedKernels() {
  local -a installed_kernels=(/lib/modules/*)
  mapfile -t fixed_kernels < "$FIXEDKERNELSFILE"
  
  for dir in ${installed_kernels[@]}; do
    local v="$(basename "$dir")"
    if ! ArrayContains fixed_kernels "-v=$v" -q; then
      printf "%b\n" "$v"
    fi
  done
}

RebootRequired() {
  if [[ -f /var/run/reboot-required ]]; then
    return 0
  else
    return 1
  fi
}

FixCurrentKernel() {
  v="$(uname -r)" 

  # Update repo cache / standard move
  Log "Updating package repository cache..."
  sudo apt-get update || return $?

  # Upgrade all ZFS-related packages / extra polite not to just upgrade everything
  Log "Upgrading ZFS..."
  for pkg in $(apt list --installed 2>/dev/null | grep ^zfs | cut -d/ -f1); do
    sudo apt-mark unhold "$pkg" >/dev/null # Just in case
    sudo apt-get upgrade "$pkg" >/dev/null
  done

  # Be nice and clear out any old junk they have lying around
  sudo apt autoremove -y 2>/dev/null

  # Install the missing kernel headers
  Log "Installing the missing kernel header files..."
  sudo apt-get install -y linux-headers-$v zfs-dkms zfsutils-linux zfs-initramfs || return $?
  
  # Recompile DKMS
  Log "Recompiling DKMS..."
  sudo dkms autoinstall -k "$v" >/dev/null || return $?

  # Rebuild the current module (now with DKMS/ZFS included!)
  Log "Rebuilding the current kernel module..."
  sudo depmod -a "$v" >/dev/null || return $?
  
  # Attempt to import the configured zpools
  Log "Importing your zpools..."
  sudo zpool import -a || return $?

  # Mount the ZFS volumes
  Log "Mounting volumes..."
  sudo zfs mount -a

  # Remember this one is fixed so we don't try to fix it again (that seldom turns out well)
  SaveFixedKernel "$v"
}

ApplyFixToAllInstalledKernels() {
  for v in $(PrintAllUnfixedKernels); do
    sudo apt-get install -y "linux-headers-$v" || continue
    sudo dkms autoinstall -k "$v"
    echo "Kernel version $v has been fixed!"
    SaveFixedKernel "$v"
  done

  sudo update-initramfs -u -k all
  sudo bash -c 'echo "zfs" > /etc/modules-load.d/zfs.conf'
  sudo systemctl enable --now zfs.target zfs-import-cache.service zfs-mount.service zfs-zed.service
}

ValidateIssue() {
  local -a fixedKernels=($(PrintAllFixedKernels))
  if ArrayContains fixedKernels "$(uname -r)"; then
    Log "It appears this kernel version has already been repaired. If you're certain that this is incorrect, then you'll need to remove this version ($(uname -r)) from the file $FIXEDKERNELSFILE."
    exit 1
  fi

  Log -n "Validating that you have the issue this fix was intended to repair... "
  local output="$(sudo modprobe zfs 2>&1)"
  if [[ "$output" =~ 'key not available' ]]; then
    LogError "\nWe've detected that your issue may be related to Secure Boot. Either disable it or sign all of the affected modules"
    return 1
  elif [[ "$output" =~ 'zfs not found' ]]; then
    Log "You do!\n"

    local status="$(dkms status zfs | grep installed)"
    if [[ "$status" ]]; then
      local installed_version="$(echo "$status" | cut -d, -f2)"
      Log "Not only do you have the right issue, but it appears that you've run this script before."
      Log "ZFS was repaired on kernel ${installed_version:1} but you're now running $(uname -r)"
    fi
    return 0
  elif [[ -z "$output" ]]; then
    Log "\nYou do not appear to be having any issues with ZFS that this script can detect."
    SaveFixedKernel
    return 1
  else
    local -l choice
    Log "\nOur probing returned an unknown response: $output"
    read -n1 -p "It's your call if you want to try anyway. Should we throw caution to the wind [y/N]? " choice; echo
    [[ "$choice" == 'y' ]] && return 0 || return 1
  fi
}

ParseCLI() {
  case "$1" in
    -h | --help | ?)
      Help
      return 1 ;;
    -l | --list)
      Log "Current Kernel Version: $(uname -r)"
      Log
      Log "Installed and Unfixed Kernels:"
      PrintAllUnfixedKernels
      return 1 ;;
    "")
      return 0 ;;
    *)
      Help
      return 2 ;;
  esac
}

ParseCLI "$@" || exit $(( $? - 1 ))

if ValidateIssue; then
  if FixCurrentKernel; then
    Log "It looks like ZFS is now running with your configured pools loaded! Ain't that a relief?\n"
    CanRun zfs-status && zfs-status || zfs status
  else
    LogError "It looks like we ran into some unforseen difficulties. You might want to Google those error messages!"
    exit 1
  fi
fi

Log "There's nothing more we can do with the current environment right now, but you also have the following unfixed kernels installed:"
PrintAllUnfixedKernels

declare -l fixall
read -n1 -p "Would you like to apply this fix to all installed kernels?" fixall; echo
if [[ "$fixall" == 'y' ]]; then
  ApplyFixToAllInstalledKernels
fi

if RebootRequired; then
  declare -l reboot
  read -n1 -p "The OS thinks you need to reboot. You wanna do that (we'll give ya 5 minutes to wrap up other work first) [y/N]? " reboot; echo
  [[ "$reboot" == 'y' ]] && sudo shutdown -r +5
fi
