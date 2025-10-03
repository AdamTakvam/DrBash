# 
# The following lines are things that are either specific to Dr. Bash 
#   for making it easier to use across login sessions or
#   little hacks to make the shell just a tiny bit less obnoxious.
#
# Lines with a '# ***' comment at the end pertain to Dr. Bash
# Those you definitely want to merge into your .bashrc file.
# The rest are entirely optional.
#

# Fix for weird escaping behavior when autocompleting paths containing variables
shopt -s direxpand

# Fix for insane disappearing command history bug
shopt -s histappend
PROMPT_COMMAND='history -a; history -n'

# ** matches files recursively (ls **/*.txt)
shopt -s globstar

# Enables advanced globbing like !(foo|bar)
shopt -s extglob

# Auto-correct minor typos in directory names (cd /usre/bin → /usr/bin)
shopt -s cdspell

# Add fuzzy keybindings (requires installing fzf)
source /usr/share/doc/fzf/examples/key-bindings.bash

### Git branch-aware prompt
PS1='\u@\h:\w$(git branch 2>/dev/null | grep "^\*" | sed "s/^\* / (/;s/$/)/")\$ '

# This umask lets everyone read anythging you create by default
# But only users in your primary group can edit
umask 002  # rwxrwxr-x

### Dr. Bash environment variables
export USERSRC="$HOME/drbash"           # ***
export USERLIB="$USERSRC/lib"           # ***
export USERENV="$USERSRC/env"           # ***
export USERBIN="$(readlink ~/bin)"      # *** 
export USERDATA="$HOME/.drbash"         # ***
export USERMEDIA="$HOME/Videos"         # ***
export MEDIAUSER="smbadmin"             # ***
export MEDIAGROUP="smbusers"            # ***

# nvim environment variables
export EDITOR='nvim'
export XDG_CONFIG_HOME=$HOME
export XDG_DATA_HOME=$HOME

### Aliases
# Some people like to put these in a seperate .aliasesrc file and source that from here. 
# You do it however you want to do it. For simplicity, I'm just putting them here.

# magic trick to make aliases work in sudo and subshells
alias sudo='sudo '
alias bashc='bash -c '
alias nohup='nohup '
alias Run='Run '                        # ***

# display
alias cls='clear'
alias clr='cls'

# file listing
export LS_OPTIONS='-h --color=auto --group-directories-first'
alias ls="ls $LS_OPTIONS $@"
alias ll="ll $LS_OPTIONS $@"            # ***  
eval "`dircolors`"

alias l='ls -1A'
alias la='ls -a'
alias lla='ll -a'

# file navigation & organization
#   always make eligible files sparse
alias cp='cp -p --sparse=always'
alias cpr='cp -r'
alias cpl='cp -l'
alias mv='mv -i'
alias mvn='mv -n'
alias mvu='mv -u'
alias diff='diff --color'

# file admin
alias chown='sudo chown'
alias chgrp='sudo chgrp'
alias chmod='sudo chmod'
alias lsof='sudo lsof'

# recycle bin / trash
alias rm='trashcan'                     # ***
alias lstrash='sudo trash-list'
alias rmtrash='sudo trash-rm'
alias undelete='sudo trash-restore'
alias restore='sudo trash-restore'
alias restore-trash='sudo trash-restore'

# kernel admin
alias ps='sudo ps'
alias kill='sudo kill'
alias modprobe='sudo modprobe'
alias lsmod='sudo lsmod'
alias shutdown='sudo shutdown -P now'
alias reboot='sudo shutdown -r now'
alias restart='reboot'

# storage admin
alias fdisk='sudo fdisk'
alias mount='sudo mount'
alias umount='sudo umount'
alias zpool='sudo zpool'
alias zfs='sudo zfs'
alias dkms='sudo dkms'
alias df='df -hT'
alias dirsize='du -hc -d1 | sort -h'

# user and group admin
alias visudo='sudo visudo'
alias useradd='sudo useradd'
alias adduser='useradd'
alias userdel='sudo userdel'
alias deluser='userdel'
alias usermod='sudo usermod'
alias groupadd='sudo groupadd'
alias addgroup='groupadd'
alias groupdel='sudo groupdel'
alias delgroup='groupdel'
alias groupmod='sudo groupmod'

# networking
alias ss='sudo ss'
alias firewall='sudo firewall-cmd'
alias nftables='sudo nft'
alias iptables='sudo iptables'
alias nmcli='sudo nmcli'
alias dhclient='sudo dhclient -4 -v'

# internet shizzle
alias curl='curl -L -v'

# bluetooth
alias btctl='bluetoothctl'

# package management
alias apt='sudo apt'
alias apt-mark='sudo apt-mark'
alias apt-clean='apt-mark minimize-manual && apt autoremove -y'
alias apt-upgrade='apt update && apt upgrade -y && apt-clean'
alias apt-update='apt-upgrade'
alias upgrade='apt-upgrade'
alias update='apt-upgrade'
alias dpkg='sudo dpkg'
alias apt-get='sudo apt-get'
alias apt-cache='sudo apt-cache'
alias aptitude='sudo aptitude'
alias synaptic='sudo synaptic'

# systemd services
alias systemctl='sudo systemctl'
alias kill='sudo kill'
alias ps='sudo ps'

# file editing
alias vim='nvim'
alias vi='nvim'

# string molestation
alias igrep='grep -i'

# misc
alias fif='findinfiles'                 # ***
alias which='type -a'
alias sw='superwhich'                   # ***

### user-developed aliases and functions
for script in $USERENV/*; do            # ***
  [ -r "$script" ] && source "$script"  # ***
done                                    # ***

### additional custom login actions
for script in $HOME/login.*; do
  [ -x "$script" ] && env "$script"
done

# Only perform the following actions if this script is being run from an interactive prompt
# This is necessary to counter bugs in scp and sftp which do not tolerate any output from
#   user startup scripts.
if [[ -t 1 ]]; then
  zfs-status -e                         # *** Only if you use ZFS, obv

  # Display CPU core tewperatures
  sensors-color                         # ***
  [[ $? == 2 ]] && glances
fi

# Custom color file listing
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=17;10:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:'
