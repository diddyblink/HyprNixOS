{ config, pkgs, ... }:

{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";
  programs.home-manager.enable = true;

  # Pacchetti utente
  home.packages = with pkgs; [
    hyprland
    hyprpaper
    hyprlock
    waybar
    kitty
    git
    scid  # vedi §3
    # scid_vs_pc  # opzionale, GUI alternativa
  ];

  # Symlink gestiti da Home Manager verso i file nel repo
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      // esempio minimale
      "layer": "top",
      "modules-right": ["clock"]
    }
  '';

  # Esempio: variabili utili
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
  };

  # Versione Home Manager (per riproducibilità)
  home.stateVersion = "24.05";
}
