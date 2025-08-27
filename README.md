# HyprNixOS — My NixOS + Hyprland Journey 🚀

This repository contains the **declarative configuration of my personal laptop (Dell, codename `Metapod`)**, built with **NixOS, Flakes, and Home Manager**, running the **Hyprland** compositor on Wayland.

---

## 📖 Motivation

I started with a **single messy `configuration.nix`** just to get NixOS running.  
Over time, I realized the importance of structure, reproducibility, and clarity.  

This repo is the result of that evolution:
- From a flat, improvised config → to a **flake-based, modular setup**.
- From unmanaged dotfiles → to **Home Manager** handling user configuration.
- From plaintext secrets → to **sops-nix** with encrypted password hashes.
- From pushing only via terminal → to **GitHub pushes directly from Codium**, after fixing agent/Wayland integration.

---

## ⚡ Key Achievements

- **Bootloader cleanup**  
  Fixed invalid systemd-boot entries created during early experiments.
- **Display/login**  
  Replaced heavy display managers with **greetd + tuigreet**: minimal TUI greeter that spawns Hyprland directly.
- **Secrets management**  
  Integrated **sops-nix** with `age` keys. User password hash is committed encrypted, never in plaintext.
- **SSH & GitHub integration**  
  Solved a tricky issue where Codium could not push via SSH (no `SSH_AUTH_SOCK`).  
  Fixed by running a **per-user ssh-agent as a systemd --user service** and wiring in `ksshaskpass` for GUI prompts on Wayland.
- **Performance tuning**  
  Disabled `NetworkManager-wait-online` to speed up boot.  
  Limited boot generations to keep `/boot` tidy.
- **Lock screen UX**  
  Customized **Hyprlock**: blurred wallpaper, large clock, PAM integration for password validation.

---

## 🛠️ Tech Stack

- **Operating System**: NixOS 24.11  
- **Compositor**: Hyprland (Wayland) + Waybar, Hyprpaper, Hyprlock  
- **Login**: greetd + tuigreet  
- **Secrets**: sops-nix + `age`  
- **Systemd user services**: ssh-agent, hyprpaper  
- **Development tools**: Podman, kubectl, kind, opentofu, VSCodium with curated extensions  
- **Other software**: GitHub Desktop, scid (chess analysis), micro, Firefox  

---

## 🗂️ Repository Structure

```text
nixos/
  hosts/
    Metapod/
      configuration.nix
      hardware-configuration.nix
home/
  diddy/
    home.nix
    hypr/
      hyprland.conf
      hyprlock.conf
secrets/
  diddy-password.txt   # encrypted with sops-nix
flake.nix
```
---

## 🚀 Usage

Clone this repository and switch to the configuration with:

```bash
# Show available flake outputs
nix flake show

# Rebuild and activate system configuration
sudo nixos-rebuild switch --flake .#Metapod
```
---

## 🎯 Why It Matters

This repository is more than just “dotfiles”:  
it reflects a mindset of **Infrastructure as Code (IaC)** applied to my personal workstation.

- ✅ Declarative system with **NixOS + Flakes**  
- ✅ User environment fully managed with **Home Manager**  
- ✅ Secrets stored encrypted with **sops-nix**  
- ✅ Modern Wayland desktop powered by **Hyprland**  
- ✅ Real troubleshooting stories (bootloader cleanup, SSH agent integration, lock screen customization)  
- ✅ Demonstrates curiosity, problem-solving, and professional discipline in system design  

---

## 🧩 Next Steps

Planned improvements and experiments:

- [ ] Explore **dual boot** with Gentoo alongside NixOS  
- [ ] Further customize **Hyprlock** (avatar, larger clock, refined blur)  
- [ ] Add **badges** (NixOS, Flakes, IaC, Hyprland) for better repo visibility  
- [ ] Experiment with **`nixos-rebuild build-vm`** to spin up ephemeral test environments  
- [ ] Polish documentation with more details on **greetd + tuigreet setup**  

---

