#!/bin/bash

cur_dir=$(pwd)

# checagem por root
show_help() {
    echo "Usage: sudo $0 [options]"
    echo
    echo "This script requires superuser privileges. Please run as 'sudo' or 'root'."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    # Add other options here as needed
}

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root or with sudo." >&2
    show_help
    exit 1
fi

# adiciona -h e --help
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -h | --help )
    show_help
    exit 0
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

###
# PREPARAÇÃO
###

# verificar instalação de sistema
get_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|endeavour|manjaro)
                echo "arch"
                ;;
            fedora|rhel|centos)
                echo "fedora"
                ;;
            debian|ubuntu|pop)
                echo "debian"
                ;;
        esac
    else
        echo "Your Linux distro is not supported by this script."
        return 1
    fi
}

run_function(){
  local func_name=$1
  if declare -f "$func_name" > /dev/null; then
    $func_name
    exit 0
  fi
}
###
# DEFINIÇÃO
###

# configurar gerenciador de pacotes
setup_pacman(){
  # backup da configuração original
  if [ -f /etc/pacman.conf.bkp ]; then
    read -rp "Do you want to overwrite your pacman.conf.bkp? [y/N]: " overwrite_pacman
    overwrite_pacman="${overwrite_pacman:-N}"
    case "$overwrite_pacman" in
      [yY]* )
        echo "Overwriting old /etc/pacman.conf.bkp"
        mv /etc/pacman.conf /etc/pacman.conf.bkp
        cp "$files/pacman.conf" "/etc/pacman.conf"
    echo ""
        return 0 ;;

      [nN]* )
        echo "Copying new pacman.conf without overwriting the old backup"
        cp "$files/pacman.conf" "/etc/pacman.conf"
    echo ""
        return 0 ;;
    esac
  else
    echo "Backing up old /etc/pacman.conf to /etc/pacman.conf.bkp..."
    mv /etc/pacman.conf /etc/pacman.conf.bkp
    echo "Copying new pacman configuration..."
    cp "$files/pacman.conf" "/etc/pacman.conf"
    echo ""
  fi
}

setup_chaotic(){
  read -rp "Do you want to enable 'chaotic AUR' repo? [y/N]: " enable_chaotic
  enable_chaotic="${enable_chaotic:-N}"
  case "$enable_chaotic" in
    [yY]* )
      echo "Setting up chaotic AUR GPG Keys"
      pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
      pacman-key --lsign-key 3056513887B78AEB
      echo "Adding the repo to mirrorlist"
      pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
      pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

      echo "Adding the repo to pacman.conf"
      echo ""
      if ! grep -Fxq "chaotic" /etc/pacman.conf ; then
        echo "[chaotic-aur]" >> /etc/pacman.conf
        echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
      fi

      return 0 ;;
    [nN]*)
      echo ""
      return 0 ;;
  esac
}

want_nopasswd(){
  read -rp "Do you want to have you 'sudo' command without password confirmation? [Y/n]: " confirm_sudo
  confirm_sudo=${confirm_sudo:-y}
  case "$confirm_sudo" in
    [yY]* )
      create_sudoers
      return 0
    ;;
    [nN]*)
      echo "Skipping sudo without password configuration"
      return 0
    ;;
  esac
  
}

check_user(){
  user=$(grep '/home' /etc/passwd | cut -d':' -f1)
  user_count=$(echo "$user" | wc -l)
  echo "This script will perform various actions that will need your user." 
  read -rp "The script detected the user: $user. Is that your main user? [Y/n]: " get_user
  get_user=${get_user:-y}

  if [ "$user_count" -gt 1 ]; then
    echo "Your system may have multiple users configured."
    read -rp "What is your main user name?" user
  fi

  declare -g user
}

create_sudoers(){
  echo "Starting the 'sudoers' configuration"
  sudoers_dir="/etc/sudoers.d"
  declare -g sudoers_dir
  if [ -d "$sudoers_dir" ]; then
    echo "Skipping the creation of '/etc/sudoers.d'. It already exists..."
    if ! grep -R "$user" "$sudoers_dir" | grep NOPASSWD ; then
      echo "Configuring sudo without password."
      echo "$user ALL=(ALL) NOPASSWD: ALL" >> "$sudoers_dir/$user"
    else
      echo "Your user is already configured with NOPASSWD (probably)"
    fi
  else
    echo "creating /etc/sudoers.d"
    mkdir -p $sudoers_dir
    touch "$sudoers_dir/$user"
    echo "$user ALL=(ALL) NOPASSWD: ALL" >> "$sudoers_dir/$user"
  fi
}

yay_install(){
    su - "$user" -c "rm -rf $cur_dir/yay"
    su - "$user" -c "mkdir $cur_dir/yay && cd yay && curl -OJs 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay' && makepkg -si --needed --noconfirm && rm -rf $cur_dir/yay"
    return 0
}

nix_install(){
  read -rp "Do you want to install the NIX package manager? [Y/n] " install_nix
  install_nix=${install_nix:-y}
  case "$install_nix" in
    [yY]* )
      echo "Starting Nix installation"
      curl -L -s https://nixos.org/nix/install | sh -s -- --daemon
      rm nix-install.sh
      return 0
      ;;
    [nN]* ) echo "Skipping the Nix package manager installation"
      return 0
      ;;
  esac
}

arch_update_system(){
  pacman -Syu --noconfirm 
  su - "$user" -c "yay -Syu --noconfirm"
  su - "$user" -c "flatpak update -y"
}

arch_pkg_install(){
  if [ -f "$files/pacman-$1.txt" ]; then 
    pacman -S --noconfirm --needed - < "$files/pacman-$1.txt"
  fi
  if [ -f "$files/aur-$1.txt" ]; then 
    sudo -u "$user" bash -c "yay -Syu --noconfirm --needed - < $files/aur-$1.txt"
  fi
  if [ -f "$files/flatpak-$1.txt" ]; then 
    su - "$user" -c "cat '$files/flatpak-$1.txt' | xargs flatpak install -y"
  fi
}


###
# EXECUÇÃO
###
distro=$(get_distro)
files="$cur_dir/files/$distro"

check_user

if [ "$#" -gt 0 ]; then
  run_function "$1"
fi

want_nopasswd

if [ "$distro" == "arch" ]; then
  #setup_pacman
  #setup_chaotic
  #yay_install
  #nix_install
  arch_update_system
  arch_pkg_install core
  arch_pkg_install utils
  arch_pkg_install tools
  arch_pkg_install gaming
  arch_pkg_install desktop
  arch_pkg_install browser
  arch_pkg_install work
  arch_pkg_install codecs
  arch_pkg_install virt
  arch_pkg_install nvidia
fi

