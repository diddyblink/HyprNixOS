# ─────────────────────────────────────────────────────────────────────────────
# NixOS host: Metapod
#
# This is the *system-level* configuration.
# Highlights:
# - Hyprland compositor on Wayland, greetd + tuigreet for login.
# - Flakes + Home Manager integration.
# - Secrets via sops-nix (encrypted password).
# - Development UX: per-user SSH agent (systemd --user) + ksshaskpass for Codium.
# - Sections are grouped (Boot, Networking, Locale, Host, Security, Graphics, …).
# ─────────────────────────────────────────────────────────────────────────────

{ config, lib, pkgs, ... }:

{
  # ────────────────────────────────────────────────────────────────────────────
  # Imports
  # ────────────────────────────────────────────────────────────────────────────
  imports = [
    ./hardware-configuration.nix
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Bootloader
  # ────────────────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 8;

  # ────────────────────────────────────────────────────────────────────────────
  # Networking
  # ────────────────────────────────────────────────────────────────────────────
  networking.hostName = "Metapod";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  services.dbus.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Locale & Console
  # ────────────────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Display stack – Hyprland + greetd/tuigreet
  # ────────────────────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # run legacy X11 apps
  };

  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };

  # Make sure no X11 display manager interferes
  services.displayManager.enable = lib.mkForce false;
  services.displayManager.sddm.enable = lib.mkForce false;

  # Desktop portals (Wayland apps → file pickers, screen sharing, etc.)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # System-side Waybar (configs are in Home Manager)
  programs.waybar.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Security / PAM / Lock screen
  # ────────────────────────────────────────────────────────────────────────────
  security.polkit.enable = true;
  programs.dconf.enable = true;

  # Hyprlock PAM stack → uses same rules as "login"
  security.pam.services.hyprlock = {
    text = ''
      auth     include login
      account  include login
      password include login
      session  include login
    '';
  };

  # gnome-keyring starts in greetd sessions (for storing secrets, not SSH)
  security.pam.services.greetd.text = ''
    auth     include login
    account  include login
    password include login
    session  include login
    session  optional pam_gnome_keyring.so auto_start
  '';
  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;

# ────────────────────────────────────────────────────────────────────────────
  # Graphics & Input (OTTIMIZZATO PER GEFORCE NOW)
  # ────────────────────────────────────────────────────────────────────────────
  # Abilita accelerazione hardware e driver Intel specifici
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Driver moderno per CPU Intel (Broadwell+)
      vaapiIntel         # Driver legacy (necessario per alcune app)
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [ "intel" ];
  services.libinput.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Secrets with sops-nix
  # ────────────────────────────────────────────────────────────────────────────
  sops.age.keyFile = "/home/diddy/.config/sops/age/keys.txt";

  sops.secrets."diddy-password" = {
    sopsFile = ../../../secrets/diddy-password.txt;
    format = "binary";
    neededForUsers = true;
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Host User
  # ────────────────────────────────────────────────────────────────────────────
  users.users.diddy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "podman" "audio" "video" ];
    hashedPasswordFile = config.sops.secrets."diddy-password".path;
    packages = with pkgs; [ tree ];
    shell = pkgs.bash;
    home = "/home/diddy";
  };
  home-manager.backupFileExtension = "backup";

  # ────────────────────────────────────────────────────────────────────────────
  # Developer UX (SSH agent, Askpass)
  # ────────────────────────────────────────────────────────────────────────────
  programs.ssh.startAgent = false;   # disable system agent → we use user-level
  environment.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
  environment.variables.SSH_ASKPASS = lib.mkForce "${pkgs.ksshaskpass}/bin/ksshaskpass";

# ────────────────────────────────────────────────────────────────────────────
  # Packages (system-wide)
  # ────────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core desktop
    hyprland waybar hyprpaper wofi dunst kitty xfce.thunar
    firefox wget curl git unzip p7zip htop neofetch
    alacritty xterm google-chrome

    # Dev & build
    gcc gnumake azure-cli

    # Containers & IaC
    podman opentofu terraform kubectl kind

    # GitHub GUI
    github-desktop

    # Node.js stack
    nodejs node-red nodePackages.npm

    # Secrets & crypto
    age

    # Chess
    scid

# VSCodium with curated extensions
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        # --- Estensioni standard (gestite da NixOS) ---
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
        redhat.vscode-yaml
        ms-kubernetes-tools.vscode-kubernetes-tools 
        redhat.ansible
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # --- Estensioni dal Marketplace---
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.47.2";
          sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        }
      ];
    })

    # SSH UX
    ksshaskpass gnome-keyring libsecret

    # Editor CLI (Micro)
    micro

  ]; 

# ────────────────────────────────────────────────────────────────────────────
  # Podman & Variabili Sessione (Devono stare FUORI dalla lista packages)
  # ────────────────────────────────────────────────────────────────────────────
  environment.sessionVariables.KIND_EXPERIMENTAL_PROVIDER = "podman";
  virtualisation.podman.enable = true;

  
# ────────────────────────────────────────────────────────────────────────────
  # Configurazione Neovim (Corretta per System-wide)
  # ────────────────────────────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure = {
      customRC = ''
        set number relativenumber
      '';
    };
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Fonts
  # ────────────────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-emoji
    liberation_ttf dejavu_fonts
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Services
  # ────────────────────────────────────────────────────────────────────────────
  services.openssh.enable = true;
  services.node-red.enable = true;
  systemd.services.node-red = {
    environment.NODE_RED_SETTINGS_FILE = "/var/lib/node-red/settings.js";
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Nix & System state
  # ────────────────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.stateVersion = "24.11";
}
