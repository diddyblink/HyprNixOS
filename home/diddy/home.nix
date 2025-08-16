{ config, pkgs, ... }:
{
  home.username = "diddy";
  home.homeDirectory = "/home/diddy";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    hyprland hyprpaper hyprlock waybar kitty
    scid
  ];

services.hyprpaper = {
  enable = true;
  settings = {
    ipc = "on";
    preload = [ "/path/al/tuo/wallpaper.jpg" ];
    wallpaper = [ "eDP-1,/path/al/tuo/wallpaper.jpg" ];
  };
};

  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
  };

  home.stateVersion = "24.11";
}
