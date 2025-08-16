# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Metapod"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
   networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
   services.dbus.enable = true;

  # Set your time zone.
   time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
   i18n.defaultLocale = "it_IT.UTF-8";
   console = {
     font = "Lat2-Terminus16";
     #keyMap = "it";
     useXkbConfig = true; # use xkb.options in tty.
   };

  # Enable the X11 windowing system.
  
  # services.xserver = {
   #	enable = true;
#	layout = "it";
 #       displayManager.lightdm.enable = true;
#	};


  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };
  
programs.hyprland = {
    # Install the packages from nixpkgs
    enable = true;
    # Whether to enable XWayland
    xwayland.enable = true;
  };

programs.waybar.enable = true;

 # Polkit (permessi GUI, tipo shutdown, mount USB ecc.)
  security.polkit.enable = true;

  # Dconf (impostazioni GNOME, richiesto da alcune app)
  programs.dconf.enable = true;

  # XWayland (necessario per far girare app X11 su Wayland)
  services.xserver.enable = true;
  #services.displayManager.sddm.enable = true;  # o gdm, lightdm...

  # Display manager (login grafico)
  services.displayManager.enable = true;
  services.displayManager.sddm.enable = true; # o un altro

  # xdg-desktop-portal (necessario per schermate, file picker)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # PAM per hyprlock (lock screen)
  security.pam.services.hyprlock = { };

  # Driver grafici
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "intel" ]; # o "amdgpu", "intel"

  # Font
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    dejavu_fonts
  ];

  # Configure keymap in X11
  # services.xserver.xkb.layout = "it";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
   services.libinput.enable = true;

   
# Indica dove sta la chiave privata age (NON committarla)
  sops.age.keyFile = "/home/diddy/.config/sops/age/keys.txt";

  # Dichiara il segreto: NixOS lo decritta in /run/secrets/...
  sops.secrets."diddy-password".sopsFile = ../../../secrets/diddy-password.txt;
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.diddy = {
     isNormalUser = true;
     extraGroups = [ "wheel"
"networkmanager" "podman" "audio" "video" ]; # Enable ‘sudo’ for the user.
hashedPasswordFile = config.sops.secrets."diddy-password".path;
     packages = with pkgs; [
       tree
     ];
shell = pkgs.bash;
home = "/home/diddy";
   };

   programs.firefox.enable = true;


   nixpkgs.config.allowUnfree = true; 

   
  services.node-red.enable = true;

  systemd.services.node-red = {
    environment = {
      NODE_RED_SETTINGS_FILE = "/var/lib/node-red/settings.js";
    };
  };

   
  # List packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [
     hyprland
     waybar
     hyprpaper
     wofi
     dunst
     swaylock
     swayidle
     kitty
     xfce.thunar
     wget
     curl
     git
     firefox 
     unzip
     p7zip
     gcc 
     gnumake
     htop
     alacritty
     xterm
     dunst
     neofetch
     podman
     opentofu
     gnome-keyring
     libsecret
     vscodium
(vscode-with-extensions.override {
    vscode = vscodium;
    vscodeExtensions = with vscode-extensions; [
      bbenoist.nix
      ms-python.python
      ms-azuretools.vscode-docker
      ms-vscode-remote.remote-ssh
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "remote-ssh-edit";
        publisher = "ms-vscode-remote";
        version = "0.47.2";
        sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
      }
    ];
  })
   kubectl
   kind
   github-desktop
   nodejs
   node-red 
   nodePackages.npm
   micro
   age
   scid
   ];

environment.sessionVariables = {
  KIND_EXPERIMENTAL_PROVIDER = "podman";
};

virtualisation.podman.enable = true;
#virtualisation.vmware.host.enable = true;
#virtualisation.virtualbox.host.enable = true;
#virtualisation.virtualbox.host.enableExtensionPack = true;
#   users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
services.gnome.gnome-keyring.enable = true;
programs.seahorse.enable = true;
users.defaultUserShell = pkgs.bash;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
   services.openssh.enable = true;

  # Open ports in the firewall.
 # networking.firewall.allowedTCPPorts = [80];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
   system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
  nix = {
  package = pkgs.nixVersions.stable;
  extraOptions = ''
    experimental-features = nix-command flakes
  '';
};

}

