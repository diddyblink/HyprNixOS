# ─────────────────────────────────────────────────────────────────────────────
# Home Manager config for user diddy
#
# This is the *user-level* configuration.
# Highlights:
# - Hyprland dotfiles (hyprland.conf, hyprlock.conf).
# - Hyprpaper (wallpaper manager).
# - Per-user SSH agent via systemd --user (exported socket).
# - Session variables for Wayland apps.
# ─────────────────────────────────────────────────────────────────────────────

{ pkgs, ... }:

{
  home.username = "diddy";
  home.homeDirectory = "/home/diddy";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # ────────────────────────────────────────────────────────────────────────────
  # Per-user ssh-agent (systemd --user service)
  # ────────────────────────────────────────────────────────────────────────────
  systemd.user.services.ssh-agent = {
    Unit = {
      Description = "User SSH agent";
      Documentation = [ "man:ssh-agent(1)" ];
      PartOf = [ "default.target" ];
    };
    Service = {
      Type = "simple";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";   # auto-add keys when used
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Session environment variables (Wayland UX)
  # ────────────────────────────────────────────────────────────────────────────
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Packages (user-level, complements system ones)
  # ────────────────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    hyprpaper hyprlock waybar kitty
    scid
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Hyprpaper – wallpaper manager
  # ────────────────────────────────────────────────────────────────────────────
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      preload = [ "/home/diddy/Immagini/Desktop.jpg" ];
      wallpaper = [ "eDP-1,/home/diddy/Immagini/Desktop.jpg" ];
    };
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Hyprland & Hyprlock configs – pulled from repo
  # ────────────────────────────────────────────────────────────────────────────
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;
}
