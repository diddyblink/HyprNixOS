{ config, pkgs, ... }:
{
  home.username = "diddy";
  home.homeDirectory = "/home/diddy";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    hyprland hyprpaper hyprlock waybar kitty
    scid
  ];

  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
  };

  home.stateVersion = "24.11";
}
