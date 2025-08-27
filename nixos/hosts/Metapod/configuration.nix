# NixOS host: Metapod
# Key ideas (for recruiters 🙋‍♂️):
# - Flakes + Home Manager + Hyprland on Wayland.
# - greetd + tuigreet (no classic X11 display manager).
# - Secrets with sops-nix (binary file, needed at user creation).
# - Fast boot (no wait-online), polished UX (xdg portals, fonts).
# - Dev UX: GNOME Keyring as SSH agent + ksshaskpass popup for Codium pushes.

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
  # Keep a reasonable number of boot entries to prevent clutter
  boot.loader.systemd-boot.configurationLimit = 8;

  # ────────────────────────────────────────────────────────────────────────────
  # Networking
  # ────────────────────────────────────────────────────────────────────────────
  networking.hostName = "Metapod";
  networking.networkmanager.enable = true;

  # Avoid blocking the boot while waiting for connectivity
  systemd.services.NetworkManager-wait-online.enable = false;

  services.dbus.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Locale & console
  # ────────────────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;  # rely on xkb options in TTY
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Display/login stack – Wayland-first with Hyprland + greetd/tuigreet
  # ────────────────────────────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  # run X11 apps via XWayland without a full X server
  };

  # TUI greeter which launches Hyprland
  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };

  # Ensure no classic X11 display manager is enabled (we use greetd instead)
  services.displayManager.enable = lib.mkForce false;
  services.displayManager.sddm.enable = lib.mkForce false;

  # XDG portals (screen sharing, file pickers, etc.) tuned for Hyprland
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  # Waybar on the system side (configs live under $HOME via Home Manager)
  programs.waybar.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Security / PAM / Lock screen
  # ────────────────────────────────────────────────────────────────────────────
  security.polkit.enable = true;
  programs.dconf.enable = true;

  # Hyprlock uses PAM; bind it to the same 'login' stack to accept the user password
  security.pam.services.hyprlock = {
    text = ''
      auth     include login
      account  include login
      password include login
      session  include login
    '';
  };

  # Make gnome-keyring start in greetd sessions so GUI apps inherit SSH agent
  security.pam.services.greetd.text = ''
    auth     include login
    account  include login
    password include login
    session  include login
    session  optional pam_gnome_keyring.so auto_start
  '';

  # ────────────────────────────────────────────────────────────────────────────
  # Graphics
  # ────────────────────────────────────────────────────────────────────────────
  # On 24.11, 'hardware.graphics' replaces the old 'hardware.opengl'
  hardware.graphics.enable = true;
  # Explicitly pick the video driver (Intel in your case)
  services.xserver.videoDrivers = [ "intel" ];

  # ────────────────────────────────────────────────────────────────────────────
  # Input / Touchpad
  # ────────────────────────────────────────────────────────────────────────────
  services.libinput.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Secrets with sops-nix
  # ────────────────────────────────────────────────────────────────────────────
  # Private age key lives outside the repo; used to decrypt secrets at switch time
  sops.age.keyFile = "/home/diddy/.config/sops/age/keys.txt";

  # Password hash for user 'diddy' comes from an encrypted, binary secret file
  sops.secrets."diddy-password" = {
    sopsFile = ../../../secrets/diddy-password.txt;
    format = "binary";      # whole file is the secret (not a YAML/JSON key)
    neededForUsers = true;  # materialize before user creation phase
  };

  # ────────────────────────────────────────────────────────────────────────────
  # User – declarative account with password hash from sops
  # ────────────────────────────────────────────────────────────────────────────
  users.users.diddy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "podman" "audio" "video" ];
    hashedPasswordFile = config.sops.secrets."diddy-password".path;
    packages = with pkgs; [ tree ];
    shell = pkgs.bash;
    home = "/home/diddy";
  };

  # Home Manager will take over dotfiles; keep automatic backups on first adoption
  home-manager.backupFileExtension = "backup";

  # ────────────────────────────────────────────────────────────────────────────
  # Developer ergonomics (use GNOME Keyring as SSH agent in GUI sessions)
  # ────────────────────────────────────────────────────────────────────────────
  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;

  # Do NOT also spawn the OpenSSH agent → avoid two agents fighting
  programs.ssh.startAgent = false;

  # Askpass for GUI prompts (useful when pushing from Codium)
  environment.variables.SSH_ASKPASS = lib.mkForce "${pkgs.ksshaskpass}/bin/ksshaskpass";

  # ────────────────────────────────────────────────────────────────────────────
  # System-wide packages (UNIFIED – only one definition)
  # ────────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core desktop/tools
    hyprland waybar hyprpaper wofi dunst kitty xfce.thunar
    wget curl git firefox unzip p7zip htop neofetch
    alacritty xterm
    # Dev & build
    gcc gnumake
    # Containers & IaC
    podman opentofu kubectl kind
    # GitHub Desktop (optional alongside Codium)
    github-desktop
    # Node stack (for node-red and misc tools)
    nodejs node-red nodePackages.npm
    # Crypto / secrets
    age
    # Chess
    scid
    # VSCodium with curated extensions
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
    # Askpass popup for SSH on Wayland (Codium pushes)
    ksshaskpass
    # Keyrings/libs used by apps
    gnome-keyring libsecret
    # Editor you used
    micro
  ];

  # Some handy env vars
  environment.sessionVariables = {
    KIND_EXPERIMENTAL_PROVIDER = "podman";
  };

  virtualisation.podman.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Fonts
  # ────────────────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    dejavu_fonts
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Services
  # ────────────────────────────────────────────────────────────────────────────
  services.openssh.enable = true;
  services.node-red.enable = true;
  systemd.services.node-red = {
    environment = {
      NODE_RED_SETTINGS_FILE = "/var/lib/node-red/settings.js";
    };
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Licensing policy for unfree software (e.g., VSCodium codecs, etc.)
  # ────────────────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Nix settings
  # ────────────────────────────────────────────────────────────────────────────
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # ────────────────────────────────────────────────────────────────────────────
  # State version
  # ────────────────────────────────────────────────────────────────────────────
  system.stateVersion = "24.11";
}
