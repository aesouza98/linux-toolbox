# linux-toolbox
O script será executado diretamente do usuário root, logo após terminar a instalação do sistema.
# Preparação
- Verificar a distro sendo utilizada
- Configurar gerenciador de pacotes (apt - pacman - dnf)
	- utilizar template? ter um arquivo/diretório pré-configurado para copiar os arquivos?
	- configurar repositórios (Flatpak/Flathub, RPMFusion, EPEL, chaotic-aur, multilib, copr*, etc)
- Configurar sudo (sem senha)
- Perguntar qual user será usado para instalar as coisas de usuário
# Execução
- Instalar pacotes (usar lista como a do Ansible)
	- Pacotes: 
		- yay - nix - pacstall
		- Core (necessários)
		- Utils/Tools (Utilidades gerais e ferramentas)
		- Gaming (Steam, Wine, Lutris, Bottles)
		- Desktop (X11, DE/WM, Temas)
		- Browser (Navegadores)
		- Work (Python, DBeaver, venv)
		- Codecs
		- Virtualização (virt-manager, gpu-passthrough)
		- Drivers NVIDIA (nvidia_drm.fbdev=1 nvidia_drm.modeset=1 intel_iommu=on iommu=pt)
- Configurações
	- Bootloader (timeout - 3s)
	- Systemd (timeout - 10s)
	- libvirtd ****Apenas NVIDIA e Intel
		- [IOMMU](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/3) (exibir no final do script para setar a VM)
		- [scripts](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/7) (rodar e instalar)
		- [libvirtd](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/4)
	- Wine/Winetricks
	- Neovim
	- Timeshift // Snapshots
	- Dotfiles (i3 / rofi / polybar / hypr)
	- Shell (zsh / ohmyzsh / pure / plugins)
	- GTK/QT (temas, darkmode, icones, cursor)
	- Browser (flags .desktop / ~/.config/chrome-flags.conf)
	- Virtualenvs (criar e instalar módulos)
	- Gerenciadores de pacote
# Finalização
- Limpeza de cache
- Apagar arquivos temporários/lixo
